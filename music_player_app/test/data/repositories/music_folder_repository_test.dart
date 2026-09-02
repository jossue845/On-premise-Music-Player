import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

// Adjust these imports to match your project's folder structure
import 'package:music_player_app/data/repositories/music_folder_repository.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/services/filesystem_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockFilesystemService extends Mock implements FilesystemService {}

void main() {
  late MockDatabaseService mockDb;
  late MockFilesystemService mockFs;
  late MusicFolderRepository repository;

  setUp(() {
    mockDb = MockDatabaseService();
    mockFs = MockFilesystemService();
    repository = MusicFolderRepository(database: mockDb, fs: mockFs);
  });

  group('MusicFolderRepository - setMusicFolder', () {
    test('successfully opens DB, gets directory, and saves to DB', () async {
      when(() => mockDb.isOpen()).thenReturn(false);
      when(() => mockDb.open()).thenAnswer((_) async {});
      when(() => mockFs.getDirectoryPath()).thenAnswer((_) async => const Success('/storage/music'));
      when(() => mockDb.insertKVPair('musicFolder', '/storage/music'))
          .thenAnswer((_) async => const Success(unit));

      final result = await repository.setMusicFolder();

      expect(result.isSuccess(), isTrue);
      verify(() => mockDb.isOpen()).called(1);
      verify(() => mockDb.open()).called(1);
      verify(() => mockFs.getDirectoryPath()).called(1);
      verify(() => mockDb.insertKVPair('musicFolder', '/storage/music')).called(1);
    });

    test('returns Failure if getting directory path fails', () async {
      when(() => mockDb.isOpen()).thenReturn(true);
      when(() => mockFs.getDirectoryPath())
          .thenAnswer((_) async => Failure(Exception('User canceled picker')));

      final result = await repository.setMusicFolder();

      expect(result.isError(), isTrue);
      verifyNever(() => mockDb.insertKVPair(any(), any()));
    });
  });

  group('MusicFolderRepository - scanFolder', () {
    test('successfully scans an empty folder and cleans up DB', () async {
      // 1. Setup DB opening
      when(() => mockDb.isOpen()).thenReturn(true);
      
      // 2. Setup retrieving the music folder path
      when(() => mockDb.getValue('musicFolder'))
          .thenAnswer((_) async => const Success('/storage/music'));
          
      // 3. Setup FileSystem returning NO files to avoid static AudioTags.read calls
      when(() => mockFs.getSongPaths('/storage/music'))
          .thenAnswer((_) async => const Success(<String>[]));
          
      // 4. Setup DB returning old paths that need to be deleted
      when(() => mockDb.getSongPaths())
          .thenAnswer((_) async => const Success(['/storage/music/old_song.mp3']));
          
      // 5. Setup the DB deletion call
      when(() => mockDb.deleteSongs(songPaths: ['/storage/music/old_song.mp3']))
          .thenAnswer((_) async => const Success(unit));

      final result = await repository.scanFolder();

      expect(result.isSuccess(), isTrue);
      verify(() => mockDb.deleteSongs(songPaths: ['/storage/music/old_song.mp3'])).called(1);
    });

    test('triggers setMusicFolder if the path is missing from DB', () async {
      when(() => mockDb.isOpen()).thenReturn(true);
      
      // First call throws to simulate missing key, second call succeeds after setMusicFolder
      var callCount = 0;
      when(() => mockDb.getValue('musicFolder')).thenAnswer((_) async {
        if (callCount++ == 0) throw Exception('Key not found');
        return const Success('/storage/music');
      });

      // Mocks for the fallback setMusicFolder() call
      when(() => mockFs.getDirectoryPath()).thenAnswer((_) async => const Success('/storage/music'));
      when(() => mockDb.insertKVPair('musicFolder', '/storage/music'))
          .thenAnswer((_) async => const Success(unit));

      // Standard scan mocks
      when(() => mockFs.getSongPaths('/storage/music')).thenAnswer((_) async => const Success(<String>[]));
      when(() => mockDb.getSongPaths()).thenAnswer((_) async => const Success([]));
      when(() => mockDb.deleteSongs(songPaths: [])).thenAnswer((_) async => const Success(unit));

      final result = await repository.scanFolder();

      expect(result.isSuccess(), isTrue);
      // Verify setMusicFolder dependencies were hit
      verify(() => mockFs.getDirectoryPath()).called(1);
      verify(() => mockDb.insertKVPair('musicFolder', '/storage/music')).called(1);
    });
  });
}