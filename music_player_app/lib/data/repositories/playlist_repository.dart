import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/playlist/playlist.dart';
import 'package:result_dart/result_dart.dart';

class PlaylistRepository {
  final DatabaseService _database;

  PlaylistRepository({required DatabaseService database})
    : _database = database;

  /// Returns all the playlists.
  Future<Result<List<Playlist>>> getPlaylists() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getPlaylists();
  }

  /// Deletes the playlist identified bt [playlistId].
  Future<Result<void>> deletePlaylist(int playlistId) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.deletePlaylist(playlistId);
  }

  /// Adds the song identified by [songId] to the playlist identified by [playlistId].
  Future<Result<void>> addSongToPlaylist(int playlistId, int songId) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.insertPlaylistTrack(playlistId, songId);
  }

  /// Removes the song identified by [songId] from the playlist identified by [playlistId].
  Future<Result<void>> removeSongFromPlaylist(
    int playlistId,
    int songId,
  ) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.deletePlaylistTrack(playlistId, songId);
  }
}
