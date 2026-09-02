import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

// Adjust these imports to match your project's folder structure
import 'package:music_player_app/data/repositories/queue_repository.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/queue/song_queue.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockSongQueue extends Mock implements SongQueue {}

void main() {
  late MockDatabaseService mockDb;
  late QueueRepository repository;
  late MockSongQueue mockQueue;

  setUpAll(() {
    registerFallbackValue(MockSongQueue());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    repository = QueueRepository(database: mockDb);
    mockQueue = MockSongQueue();
  });

  group('QueueRepository - Database Methods', () {
    test('getQueue opens DB if closed and returns the queue', () async {
      final fakeQueue = SongQueue(songIds: UnmodifiableListView([1, 2]), currentSongIndex: 0);
      when(() => mockDb.isOpen()).thenReturn(false);
      when(() => mockDb.open()).thenAnswer((_) async {});
      when(() => mockDb.getQueue()).thenAnswer((_) async => Success(fakeQueue));

      final result = await repository.getQueue();

      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow(), equals(fakeQueue));
      verify(() => mockDb.isOpen()).called(1);
      verify(() => mockDb.open()).called(1);
      verify(() => mockDb.getQueue()).called(1);
    });

    test('saveQueue skips opening DB if already open and saves', () async {
      final fakeQueue = SongQueue(songIds: UnmodifiableListView([1, 2]), currentSongIndex: 0);
      when(() => mockDb.isOpen()).thenReturn(true);
      when(() => mockDb.saveQueue(fakeQueue)).thenAnswer((_) async => const Success(unit));

      final result = await repository.saveQueue(fakeQueue);

      expect(result.isSuccess(), isTrue);
      verify(() => mockDb.isOpen()).called(1);
      verifyNever(() => mockDb.open());
      verify(() => mockDb.saveQueue(fakeQueue)).called(1);
    });
  });

  group('QueueRepository - Logic Methods (shuffle, addSongs, removeSong)', () {
    
    test('shuffle returns identical queue if empty', () {
      when(() => mockQueue.songIds).thenReturn(UnmodifiableListView([]));
      
      final result = repository.shuffle(queue: mockQueue);
      
      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow(), equals(mockQueue));
    });

    test('shuffle randomizes all songs when keepCurrentSongAsFirst is false', () {
      final queue = SongQueue(songIds: UnmodifiableListView([10, 20, 30, 40]), currentSongIndex: 2);
      
      final result = repository.shuffle(queue: queue, keepCurrentSongAsFirst: false).getOrThrow();
      
      expect(result.songIds.length, 4);
      expect(result.songIds, containsAll([10, 20, 30, 40]));
      expect(result.currentSongIndex, 0);
    });

    test('shuffle pins current song to index 0 when keepCurrentSongAsFirst is true', () {
      final queue = SongQueue(songIds: UnmodifiableListView([10, 20, 30, 40]), currentSongIndex: 1);
      
      final result = repository.shuffle(queue: queue, keepCurrentSongAsFirst: true).getOrThrow();
      
      expect(result.songIds.length, 4);
      // The song at index 1 was '20', it should now be pinned at index 0
      expect(result.songIds.first, 20); 
      expect(result.currentSongIndex, 0);
    });

    test('shuffle returns Failure on exception', () {
      when(() => mockQueue.songIds).thenThrow(Exception('Simulated crash'));
      
      final result = repository.shuffle(queue: mockQueue);
      
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('Failed to shuffle queue.'));
    });

    test('addSongs appends new items to the end of the queue', () {
      final queue = SongQueue(songIds: UnmodifiableListView([1]), currentSongIndex: 0);
      
      final result = repository.addSongs(queue, [2, 3]).getOrThrow();
      
      expect(result.songIds, [1, 2, 3]);
      expect(result.currentSongIndex, 0);
    });

    test('addSongs returns Failure on exception', () {
      when(() => mockQueue.songIds).thenThrow(Exception('Simulated crash'));
      
      final result = repository.addSongs(mockQueue, [1, 2]);
      
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('Failed to add songs to the queue.'));
    });

    test('removeSong removes target and clamps index appropriately', () {
      final queue = SongQueue(songIds: UnmodifiableListView([10, 20, 30]), currentSongIndex: 1);

      // 1. Remove current song (index 1)
      final result1 = repository.removeSong(queue, 1).getOrThrow();
      expect(result1.songIds, [10, 30]);
      expect(result1.currentSongIndex, 1);

      // 2. Remove out of bounds (clamps to the last index, which is 2, removing '30')
      final result2 = repository.removeSong(queue, 99).getOrThrow();
      expect(result2.songIds, [10, 20]);
      expect(result2.currentSongIndex, 1);
    });

    test('removeSong returns Failure on exception', () {
      when(() => mockQueue.songIds).thenThrow(Exception('Simulated crash'));
      
      final result = repository.removeSong(mockQueue, 1);
      
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('Failed to remove song from queue.'));
    });
  });
}