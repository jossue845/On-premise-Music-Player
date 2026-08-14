import 'package:sqflite/sqflite.dart';
import '../../domain/models/scrobble/scrobble.dart';
import '../services/database_service.dart';

class ScrobbleRepository {
  final DatabaseService databaseService;
  
  // Update this to match your actual table name if different
  static const String tableName = 'scrobbles'; 

  ScrobbleRepository({required this.databaseService});

  /// Inserts a new scrobble into the local database
  Future<int> insertScrobble(Scrobble scrobble) async {
    final db = await _getDb();
    
    return await db.insert(
      tableName,
      {
        'artist': scrobble.artist,
        'track': scrobble.track,
        'album': scrobble.album,
        'timestamp': scrobble.timestamp,
        'is_synced': 0, // 0 means false (unsynced) in SQLite
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetches all scrobbles that haven't been pushed to Last.fm yet
  Future<List<Scrobble>> getUnsyncedScrobbles() async {
    final db = await _getDb();
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return maps.map((map) => Scrobble(
      id: map['id'] as int?,
      artist: map['artist'] as String,
      track: map['track'] as String,
      album: map['album'] as String?,
      timestamp: map['timestamp'] as int,
      isSynced: (map['is_synced'] as int) == 1,
    )).toList();
  }

  /// Marks a specific batch of scrobbles as successfully synced
  Future<void> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    
    final db = await _getDb();
    
    // Create a string of question marks matching the number of IDs: "?, ?, ?"
    final placeholders = List.filled(ids.length, '?').join(',');
    
    await db.update(
      tableName,
      {'is_synced': 1}, // 1 means true
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Deletes older scrobbles that have already been synced to keep the DB lean
  Future<void> deleteSyncedScrobbles() async {
    final db = await _getDb();
    
    await db.delete(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [1],
    );
  }

  // Helper method to safely get the database instance
  Future<Database> _getDb() async {
    // Assuming your DatabaseService has a getter named 'database' as we configured earlier
    return await databaseService.database; 
  }
}