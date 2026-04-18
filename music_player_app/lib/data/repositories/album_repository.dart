import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/album/album.dart';
import 'package:result_dart/result_dart.dart';

class AlbumRepository {
  final DatabaseService _database;

  AlbumRepository({required DatabaseService database}) : _database = database;

  /// Returns all the albums.
  ///
  /// Returns the albums from the artist identified by [artistId] if it is not null.
  Future<Result<List<Album>>> getAlbums({int? artistId}) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getAlbums(artistId: artistId);
  }
}
