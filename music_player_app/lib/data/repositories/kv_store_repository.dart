import 'package:music_player_app/data/services/database_service.dart';
import 'package:result_dart/result_dart.dart';

class KvStoreRepository {
  final DatabaseService _database;

  KvStoreRepository({required DatabaseService database}) : _database = database;

  /// Inserts a key-value pair in the key-value store.
  Future<Result<void>> insertKVPair(String key, String value) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.insertKVPair(key, value);
  }

  /// Returns the value associated to the provided [key].
  Future<Result<String>> getValue(String key) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getValue(key);
  }
}
