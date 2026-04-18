import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/queue/song_queue.dart';
import 'package:result_dart/result_dart.dart';

class QueueRepository {
  final DatabaseService _database;

  QueueRepository({required DatabaseService database}) : _database = database;

  /// Returns the queue.
  Future<Result<SongQueue>> getQueue() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getQueue();
  }

  /// Saves the [queue].
  Future<Result<void>> saveQueue(SongQueue queue) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.saveQueue(queue);
  }
}
