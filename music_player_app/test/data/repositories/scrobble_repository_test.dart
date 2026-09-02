import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';

// Adjust these imports to match your project's folder structure
import 'package:music_player_app/data/repositories/scrobble_repository.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/scrobble/scrobble.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabaseService mockDatabaseService;
  late MockDatabase mockDatabase;
  late ScrobbleRepository repository;

  setUpAll(() {
    // Register fallbacks for sqflite parameters if needed by mocktail
    registerFallbackValue(ConflictAlgorithm.replace);
  });

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    mockDatabase = MockDatabase();
    
    // Wire up the service to return our mock database
    when(() => mockDatabaseService.database).thenAnswer((_) async => mockDatabase);
    
    repository = ScrobbleRepository(databaseService: mockDatabaseService);
  });

  group('ScrobbleRepository Tests', () {
    
    test('insertScrobble formats data correctly and calls db.insert', () async {
      final scrobble = Scrobble(
        artist: 'Muse',
        track: 'Starlight',
        album: 'Black Holes',
        timestamp: 1620000000,
      );

      when(() => mockDatabase.insert(
        any(), 
        any(), 
        conflictAlgorithm: any(named: 'conflictAlgorithm')
      )).thenAnswer((_) async => 1); // Returns inserted row ID

      final id = await repository.insertScrobble(scrobble);

      expect(id, 1);
      verify(() => mockDatabase.insert(
        ScrobbleRepository.tableName,
        {
          'artist': 'Muse',
          'track': 'Starlight',
          'album': 'Black Holes',
          'timestamp': 1620000000,
          'is_synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      )).called(1);
    });

    test('getUnsyncedScrobbles queries db and maps results to Scrobble objects', () async {
      final mockData = [
        {
          'id': 10,
          'artist': 'Radiohead',
          'track': 'Creep',
          'album': 'Pablo Honey',
          'timestamp': 1630000000,
          'is_synced': 0,
        }
      ];

      when(() => mockDatabase.query(
        any(),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
      )).thenAnswer((_) async => mockData);

      final results = await repository.getUnsyncedScrobbles();

      expect(results.length, 1);
      expect(results.first.id, 10);
      expect(results.first.artist, 'Radiohead');
      expect(results.first.isSynced, false);

      verify(() => mockDatabase.query(
        ScrobbleRepository.tableName,
        where: 'is_synced = ?',
        whereArgs: [0],
      )).called(1);
    });

    test('markAsSynced short-circuits if ID list is empty', () async {
      await repository.markAsSynced([]);
      
      // Should not interact with the database at all
      verifyNever(() => mockDatabaseService.database);
      verifyNever(() => mockDatabase.update(any(), any()));
    });

    test('markAsSynced dynamically creates placeholders and updates rows', () async {
      when(() => mockDatabase.update(
        any(), 
        any(), 
        where: any(named: 'where'), 
        whereArgs: any(named: 'whereArgs')
      )).thenAnswer((_) async => 3); // 3 rows updated

      await repository.markAsSynced([1, 2, 3]);

      verify(() => mockDatabase.update(
        ScrobbleRepository.tableName,
        {'is_synced': 1},
        where: 'id IN (?,?,?)', // Validates placeholder generation
        whereArgs: [1, 2, 3],
      )).called(1);
    });

    test('deleteSyncedScrobbles deletes rows where is_synced is 1', () async {
      when(() => mockDatabase.delete(
        any(), 
        where: any(named: 'where'), 
        whereArgs: any(named: 'whereArgs')
      )).thenAnswer((_) async => 5);

      await repository.deleteSyncedScrobbles();

      verify(() => mockDatabase.delete(
        ScrobbleRepository.tableName,
        where: 'is_synced = ?',
        whereArgs: [1],
      )).called(1);
    });
  });
}