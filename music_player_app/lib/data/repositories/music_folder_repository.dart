import 'dart:collection';

import 'package:audiotags/audiotags.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/services/filesystem_service.dart';
import 'package:music_player_app/domain/models/album/album.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/utils/image_handler.dart';
import 'package:result_dart/result_dart.dart';

class MusicFolderRepository with ImageHandler {
  static const String _musicFolderKeyName = "musicFolder";

  final DatabaseService _database;
  final FilesystemService _fs;

  MusicFolderRepository({
    required DatabaseService database,
    required FilesystemService fs,
  }) : _database = database,
       _fs = fs;

  /// Scans the filesystem and initializes or updates the database with the found songs.
  Future<Result<void>> scanFolder() async {
    late String dirPath;

    try {
      if (!_database.isOpen()) {
        await _database.open();
      }

      try {
        dirPath = (await _database.getValue(_musicFolderKeyName)).getOrThrow();
      } on Exception {
        await setMusicFolder();
        dirPath = (await _database.getValue(_musicFolderKeyName)).getOrThrow();
      }

      final List<String> filePaths = (await _fs.getSongPaths([
        dirPath,
      ])).getOrThrow();
      final DeepCollectionEquality eq = DeepCollectionEquality.unordered();
      final List<String> pathsOfSongsToBeDeleted = [];

      for (final filePath in filePaths) {
        Tag? tag = await AudioTags.read(filePath);

        // --- NEW FORGIVING LOGIC ---
        // If the tag is null, don't skip! Just extract the filename from the path.
        String? title =
            tag?.title ??
            filePath
                .split('/')
                .last
                .replaceAll(RegExp(r"\.([A-Za-z0-9]+)$"), '');

        String? trackArtistRaw = tag?.trackArtist;
        String? album = tag?.album;
        String? albumArtistRaw = tag?.albumArtist;
        String? genre = tag?.genre;
        int? year = tag?.year;
        int? trackNumber = tag?.trackNumber;
        List<Picture> pictures = tag?.pictures ?? [];
        List<String> trackArtists;
        List<String> albumArtists;

        String? imagePath = (pictures.isNotEmpty)
            ? (await storePicture(pictures.first.bytes, _database)).getOrThrow()
            : null;

        // We can safely remove the "if (title == null) { continue; }" block
        // because we guaranteed a title above using the filename!

        if (trackArtistRaw == null || trackArtistRaw.isEmpty) {
          trackArtists = ["Unknown Artist"];
        } else {
          trackArtists = _parseArtists(trackArtistRaw);
        }

        if (albumArtistRaw == null || albumArtistRaw.isEmpty) {
          albumArtists = trackArtists;
        } else {
          albumArtists = _parseArtists(albumArtistRaw);
        }

        if (album == null) {
          album = "Unknown Album"; // Give it a default album name if missing
          albumArtists = [
            "Unknown Artist", // Default album artist to group all the albumless songs under a single "Unknown Album".
          ];
        }

        List<Song> queryResult = (await _database.getSongs(
          path: filePath,
        )).getOrThrow();

        if (queryResult.isNotEmpty) {
          Song dbSong = queryResult.first;
          Album dbAlbum = (await _database.getAlbums(
            songId: dbSong.id,
          )).getOrThrow().first;
          Song foundSong = Song(
            title: title,
            id: dbSong.id,
            artists: UnmodifiableListView([]),
            album: album,
            albumId: dbSong.albumId,
            genre: genre,
            year: year,
            trackNumber: trackNumber,
            path: filePath,
            imagePath: imagePath,
          );

          // Check if song metadata is different and update it if it is.
          if (dbSong.copyWith(artists: UnmodifiableListView([])) != foundSong ||
              !eq.equals(dbSong.artists, trackArtists) ||
              !eq.equals(dbAlbum.albumArtists, albumArtists)) {
            (await _database.updateTags(
              oldSong: dbSong,
              newTitle: title,
              newTrackNumber: trackNumber,
              newGenre: genre,
              newYear: year,
              newAlbumTitle: album,
              newSongArtistNames: trackArtists,
              newAlbumArtistNames: albumArtists,
              newPath: imagePath,
            )).getOrThrow();
          }
        } else {
          // Check if song was present but with a different path and update the path if it was.
          queryResult = (await _database.getSongsWith(
            title: title,
            genre: genre,
            year: year,
            trackNumber: trackNumber,
          )).getOrThrow();
          final List<Song> filteredQueryResult = [];

          for (final s in queryResult) {
            if ((s.artists.length == trackArtists.length &&
                    s.artists.toSet().containsAll(trackArtists.toSet())) &&
                s.album == album) {
              filteredQueryResult.add(s);
              break;
            }
          }
          if (filteredQueryResult.isNotEmpty) {
            (await _database.updateTags(
              oldSong: filteredQueryResult.first,
              newPath: filePath,
            )).getOrThrow();
          } else {
            // If the song wasn't present, add it.
            (await _database.insertSong(
              title: title,
              path: filePath,
              albumTitle: album,
              songArtistNames: trackArtists,
              albumArtistNames: albumArtists,
              genre: genre,
              year: year,
              trackNumber: trackNumber,
              imagePath: imagePath,
            )).getOrThrow();
          }
        }
      }

      // Check if there are songs in the db that are no longer present on disk and delete them.
      final dbPaths = (await _database.getSongPaths()).getOrThrow();
      for (final song in dbPaths) {
        if (!filePaths.contains(song)) {
          pathsOfSongsToBeDeleted.add(song);
        }
      }
      (await _database.deleteSongs(
        songPaths: pathsOfSongsToBeDeleted,
      )).getOrThrow();

      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Parse [artistsString], a string containing multiple artists separated by ";" or "/", and return the artists as a list.
  List<String> _parseArtists(String artistsString) {
    List<String> artists = artistsString.split(RegExp(r"[;/]"));
    return artists.map((a) => a.trim()).toList();
  }

  /// Prompts the user to select the folder they want to scan for music files.
  Future<Result<void>> setMusicFolder() async {
    try {
      if (!_database.isOpen()) {
        await _database.open();
      }
      final String dirPath = (await _fs.getDirectoryPath()).getOrThrow();
      (await _database.insertKVPair(_musicFolderKeyName, dirPath)).getOrThrow();
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
