import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

// Adjust these imports to match your project's folder structure
import 'package:music_player_app/data/repositories/playlist_repository.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/playlist/playlist.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockPlaylist extends Mock implements Playlist {}

void main() {
  late MockDatabaseService mockDb;
  late PlaylistRepository repository;

  setUp(() {
    mockDb = MockDatabaseService();
    repository = PlaylistRepository(database: mockDb);
  });

  group('PlaylistRepository Tests', () {
    final mockPlaylists = [MockPlaylist(), MockPlaylist()];

    test('getPlaylists opens DB if closed and returns playlists', () async {
      when(() => mockDb.isOpen()).thenReturn(false);
      when(() => mockDb.open()).thenAnswer((_) async {}); 
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => Success(mockPlaylists));

      final result = await repository.getPlaylists();

      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow(), equals(mockPlaylists));
      
      verify(() => mockDb.isOpen()).called(1);
      verify(() => mockDb.open()).called(1);
      verify(() => mockDb.getPlaylists()).called(1);
    });

    test('createPlaylist skips opening DB if already open and returns new ID', () async {
      when(() => mockDb.isOpen()).thenReturn(true);
      when(() => mockDb.insertPlaylist('My Vibes')).thenAnswer((_) async => const Success(1));

      final result = await repository.createPlaylist('My Vibes');

      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow(), equals(1));
      
      verify(() => mockDb.isOpen()).called(1);
      verifyNever(() => mockDb.open());
      verify(() => mockDb.insertPlaylist('My Vibes')).called(1);
    });

    test('deletePlaylists delegates list of IDs to database service', () async {
      when(() => mockDb.isOpen()).thenReturn(true);
      when(() => mockDb.deletePlaylists([1, 2, 3])).thenAnswer((_) async => const Success(unit));

      final result = await repository.deletePlaylists([1, 2, 3]);

      expect(result.isSuccess(), isTrue);
      verify(() => mockDb.deletePlaylists([1, 2, 3])).called(1);
    });

    test('addSongsToPlaylist delegates playlist ID and song IDs', () async {
      when(() => mockDb.isOpen()).thenReturn(true);
      when(() => mockDb.insertPlaylistTracks(1, [10, 11])).thenAnswer((_) async => const Success(unit));

      final result = await repository.addSongsToPlaylist(1, [10, 11]);

      expect(result.isSuccess(), isTrue);
      verify(() => mockDb.insertPlaylistTracks(1, [10, 11])).called(1);
    });

    test('removeSongsFromPlaylist delegates removal to database service', () async {
      when(() => mockDb.isOpen()).thenReturn(true);
      when(() => mockDb.deletePlaylistTracks(1, [10])).thenAnswer((_) async => const Success(unit));

      final result = await repository.removeSongsFromPlaylist(1, [10]);

      expect(result.isSuccess(), isTrue);
      verify(() => mockDb.deletePlaylistTracks(1, [10])).called(1);
    });

    test('Returns Failure if the database service throws an error', () async {
      final fakeException = Exception('Database crash');
      when(() => mockDb.isOpen()).thenReturn(true);
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => Failure(fakeException));

      final result = await repository.getPlaylists();

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull(), equals(fakeException));
    });
  });
}