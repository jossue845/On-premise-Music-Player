import 'dart:collection';

import 'package:audiotags/audiotags.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/services/filesystem_service.dart';
import 'package:music_player_app/domain/models/album/album.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:result_dart/result_dart.dart';

class SongRepository {
  final DatabaseService _database;
  final FilesystemService _fs;

  SongRepository({
    required DatabaseService database,
    required FilesystemService fs,
  }) : _database = database,
       _fs = fs;

  /// Returns all the songs.
  ///
  /// Returns the songs in the album identified by [albumId] if it is not null.
  /// Returns the songs from the artist identified by [artistId] if it is not null.
  /// Returns the songs in the playlist identified by [playlistId] if it is not null.
  Future<Result<List<Song>>> getSongs({
    int? albumId,
    int? artistId,
    int? playlistId,
  }) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getSongs(
      albumId: albumId,
      artistId: artistId,
      playlistId: playlistId,
    );
  }

  /// Updates [oldSong] with the provided metadata.
  Future<Result<Song>> editTags({
    required Song oldSong,
    String? newTitle,
    String? newGenre,
    int? newYear,
    int? newTrackNumber,
    String? newAlbumTitle,
    List<String>? newSongArtistNames,
    List<String>? newAlbumArtistNames,
  }) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.updateTags(
      oldSong: oldSong,
      newTitle: newTitle,
      newGenre: newGenre,
      newYear: newYear,
      newTrackNumber: newTrackNumber,
      newAlbumTitle: newAlbumTitle,
      newSongArtistNames: newSongArtistNames,
      newAlbumArtistNames: newAlbumArtistNames,
    );
  }

  /// Scans the filesystem and initializes or updates the database with the found songs.
  Future<Result<void>> scanFolder() async {
    try {
      final String dirPath = (await _fs.getDirectoryPath()).getOrThrow();
      final List<String> filePaths = (await _fs.getSongPaths([
        dirPath,
      ])).getOrThrow();
      final DeepCollectionEquality eq = DeepCollectionEquality.unordered();
      final List<String> pathsOfSongsToBeDeleted = [];

      if (!_database.isOpen()) {
        await _database.open();
      }

      for (final filePath in filePaths) {
        Tag? tag = await AudioTags.read(filePath);

        if (tag == null) {
          print("Null tag object from: $filePath");
          continue;
        }

        String? title = tag.title;
        String? trackArtistRaw = tag.trackArtist;
        String? album = tag.album;
        String? albumArtistRaw = tag.albumArtist;
        String? genre = tag.genre;
        int? year = tag.year;
        int? trackNumber = tag.trackNumber;
        List<Picture>? pictures = tag.pictures;
        List<String> trackArtists;
        List<String> albumArtists;

        if (title == null) {
          print("Null title in: $filePath");
          continue;
        }

        if (trackArtistRaw == null) {
          trackArtists = ["Unknown Artist"];
        } else {
          trackArtists = _parseArtists(trackArtistRaw);
        }
        if (albumArtistRaw == null) {
          albumArtists = trackArtists;
        } else {
          albumArtists = _parseArtists(albumArtistRaw);
        }
        album ??= title;

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
            bitrate: dbSong.bitrate,
            imagePath: dbSong.imagePath,
          );

          // Check if song metadata is different and update it if it is.
          if (dbSong.copyWith(artists: UnmodifiableListView([])) != foundSong ||
              !eq.equals(dbSong.artists, trackArtists) ||
              !eq.equals(dbAlbum.albumArtists, albumArtists)) {
            await _database.updateTags(
              oldSong: dbSong,
              newTitle: title,
              newTrackNumber: trackNumber,
              newGenre: genre,
              newYear: year,
              newAlbumTitle: album,
              newSongArtistNames: trackArtists,
              newAlbumArtistNames: albumArtists,
            );
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
            await _database.updateTags(
              oldSong: filteredQueryResult.first,
              newPath: filePath,
            );
          } else {
            // If the song wasn't present, add it.
            await _database.insertSong(
              title: title,
              path: filePath,
              albumTitle: album,
              songArtistNames: trackArtists,
              albumArtistNames: albumArtists,
              genre: genre,
              year: year,
              trackNumber: trackNumber,
            );
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
      await _database.deleteSongs(songPaths: pathsOfSongsToBeDeleted);

      print(filePaths.length);

      return Success(unit);
    } on Exception catch (e) {
      print(e);
      return Failure(e);
    }
  }

  /// Parse [artistsString], a string containing multiple artists separated by ";" or "/", and return the artists as a list.
  List<String> _parseArtists(String artistsString) {
    List<String> artists = artistsString.split(RegExp(r"[;/]"));
    return artists.map((a) => a.trim()).toList();
  }
}
