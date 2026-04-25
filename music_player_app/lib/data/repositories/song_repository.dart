import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/song/song.dart';
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
}
