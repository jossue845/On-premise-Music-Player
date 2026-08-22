import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDatabase;
  late SongRepository repository;

  setUp(() {
    mockDatabase = MockDatabaseService();
    repository = SongRepository(database: mockDatabase);
  });

  group('SongRepository Tests', () {
    
    test('getSongs returns an empty list when database is empty', () async {
      
      when(() => mockDatabase.isOpen()).thenReturn(true);
      when(() => mockDatabase.getSongs()).thenAnswer((_) async => const Success([]));

      final result = await repository.getSongs();

      expect(result.isSuccess(), true);
      expect(result.getOrThrow(), isEmpty);
      
      verify(() => mockDatabase.getSongs()).called(1);
    });

  });
}