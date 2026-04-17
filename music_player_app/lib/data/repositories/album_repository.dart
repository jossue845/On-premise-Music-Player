import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/album/album.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:result_dart/result_dart.dart';

class AlbumRepository {
  final DatabaseService _database;

  AlbumRepository({required DatabaseService database}) : _database = database;

  /// Return all the albums.
  Future<Result<List<Album>>> getAlbums() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getAlbums();
  }

  /// Returns all the songs that have [albumId] as album.
  Future<Result<List<Song>>> getSongs(int albumId) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getSongs(albumId: albumId);
  }
}
