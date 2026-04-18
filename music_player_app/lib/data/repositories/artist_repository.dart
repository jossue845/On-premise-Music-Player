import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/artist/artist.dart';
import 'package:result_dart/result_dart.dart';

class ArtistRepository {
  final DatabaseService _database;

  ArtistRepository({required DatabaseService database}) : _database = database;

  /// Returns all the artists.
  Future<Result<List<Artist>>> getArtists() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getArtists();
  }
}
