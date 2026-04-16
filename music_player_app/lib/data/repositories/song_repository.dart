import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:result_dart/result_dart.dart';

class SongRepository {
  SongRepository({required DatabaseService database}) : _database = database;

  final DatabaseService _database;

  /// Returns all the songs.
  Future<Result<List<Song>>> getSongs() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getSongs();
  }
}
