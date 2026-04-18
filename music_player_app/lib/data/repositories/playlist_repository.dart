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

  /// Deletes the playlists identified bt [playlistIds].
  Future<Result<void>> deletePlaylists(List<int> playlistIds) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.deletePlaylists(playlistIds);
  }

  /// Adds the songs identified by [songIds] to the playlist identified by [playlistId].
  Future<Result<void>> addSongsToPlaylist(
    int playlistId,
    List<int> songIds,
  ) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.insertPlaylistTracks(playlistId, songIds);
  }

  /// Removes the songs identified by [songIds] from the playlist identified by [playlistId].
  Future<Result<void>> removeSongsFromPlaylist(
    int playlistId,
    List<int> songIds,
  ) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.deletePlaylistTracks(playlistId, songIds);
  }
}
