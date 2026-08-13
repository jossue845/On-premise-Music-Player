import 'package:sqflite/sqflite.dart';
import '../../domain/models/scrobble/scrobble.dart';
import '../services/database_service.dart';

class ScrobbleRepository {
  final DatabaseService databaseService;

  ScrobbleRepository({required this.databaseService});

  // Save a new pending scrobble
  Future<int> insertScrobble(Scrobble scrobble) async {
    final db = await databaseService.database;
    return await db.insert('scrobbles', scrobble.toMap());
  }

  // Retrieve all scrobbles that haven't been sent to Last.fm yet
  Future<List<Scrobble>> getPendingScrobbles() async {
    final db = await databaseService.database;
    final maps = await db.query(
      'scrobbles',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => Scrobble.fromMap(map)).toList();
  }

  // Mark scrobbles as synced after a successful Last.fm API batch submission
  Future<void> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await databaseService.database;
    final idList = ids.join(',');
    await db.rawUpdate(
      'UPDATE scrobbles SET is_synced = 1 WHERE id IN ($idList)',
    );
  }

  // Clean up synced scrobbles older than 30 days to keep DB size lean
  Future<void> deleteOldSyncedScrobbles() async {
    final db = await databaseService.database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
    await db.delete(
      'scrobbles',
      where: 'is_synced = 1 AND timestamp < ?',
      whereArgs: [thirtyDaysAgo],
    );
  }
}