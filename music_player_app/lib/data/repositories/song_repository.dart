import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/utils/tag_utils.dart';
import 'package:result_dart/result_dart.dart';

class SongRepository {
  final DatabaseService _database;

  SongRepository({required DatabaseService database}) : _database = database;

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
    Uint8List? pictureBytes,
  }) async {
    Tag? oldTag = await AudioTags.read(oldSong.path);

    if (oldTag == null) {
      throw Exception("Error while editing tags");
    }

    List<Picture> songPics = oldTag.pictures;

    // Replace the old cover picture with the new picture.
    if (pictureBytes != null) {
      songPics.removeWhere((p) => p.pictureType == PictureType.coverFront);
      songPics.add(
        Picture(
          bytes: pictureBytes,
          mimeType: null,
          pictureType: PictureType.coverFront,
        ),
      );
    }

    // If the new tags are set, use those, othewise use the old ones to preserve them.
    Tag tag = Tag(
      title: (newTitle != null) ? newTitle : oldSong.title,
      // --- FIXED: Using .join() cleanly creates the string without duplicating the first item ---
      trackArtist: (newSongArtistNames != null)
          ? newSongArtistNames.join("; ")
          : oldSong.artists.join("; "),
      album: (newAlbumTitle != null) ? newAlbumTitle : oldSong.album,
      albumArtist: (newAlbumArtistNames != null)
          ? newAlbumArtistNames.join("; ")
          : (oldTag.albumArtist != null)
          ? TagUtils.parseArtists(oldTag.albumArtist!).join(";")
          : null,
      genre: (newGenre != null) ? newGenre : oldSong.genre,
      year: (newYear != null) ? newYear : oldSong.year,
      trackNumber: (newTrackNumber != null)
          ? newTrackNumber
          : oldSong.trackNumber,
      // These are tags that the app does't handle, they're here just so that they don't get deleted.
      pictures: songPics,
      trackTotal: oldTag.trackTotal,
      discNumber: oldTag.discNumber,
      duration: oldTag.duration,
      discTotal: oldTag.discTotal,
      bpm: oldTag.bpm,
      lyrics: oldTag.lyrics,
    );

    final String? imagePath = (pictureBytes != null)
        ? (await TagUtils.storePicture(pictureBytes)).getOrThrow()
        : null;

    try {
      await AudioTags.write(oldSong.path, tag);
    } on Exception catch (e) {
      stderr.writeln(e);
      return Failure(Exception("Failed to edit song tags."));
    }

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
      newImagePath: imagePath,
    );
  }

  /// Sets the favorite status of the song identified by [songId] to [favorite].
  Future<Result<void>> setFavoriteStatus(int songId, bool favorite) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.setFavoriteStatus(songId, favorite);
  }
}
