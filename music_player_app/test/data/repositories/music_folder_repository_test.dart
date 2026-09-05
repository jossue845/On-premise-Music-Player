import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

// Fix: Adjusted these imports to match the project's folder structure
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
      
      when(() => mockDb.open()).thenAnswer((invocation) async {
        return;
      });
      
      when(() => mockFs.getDirectoryPath()).thenAnswer((invocation) async {
        Result<String> successResult = Success('/storage/music');
        return successResult;
      });
      
      when(() => mockDb.insertKVPair('musicFolder', '/storage/music')).thenAnswer((invocation) async {
        Result<void> successResult = Success(unit);
        return successResult;
      });

      Result<void> result = await repository.setMusicFolder();

      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
      
      verify(() => mockDb.isOpen()).called(1);
      verify(() => mockDb.open()).called(1);
      verify(() => mockFs.getDirectoryPath()).called(1);
      verify(() => mockDb.insertKVPair('musicFolder', '/storage/music')).called(1);
    });

    test('returns Failure if getting directory path fails', () async {
      when(() => mockDb.isOpen()).thenReturn(true);
      
      when(() => mockFs.getDirectoryPath()).thenAnswer((invocation) async {
        Exception error = Exception('User canceled picker');
        Result<String> failureResult = Failure(error);
        return failureResult;
      });

      Result<void> result = await repository.setMusicFolder();

      bool isError = false;
      if (result.isError() == true) {
        isError = true;
      }
      expect(isError, true);
      
      verifyNever(() => mockDb.insertKVPair(any(), any()));
    });
  });

  group('MusicFolderRepository - scanFolder', () {
    test('successfully scans an empty folder and cleans up DB', () async {
      // Fix: Setup DB opening with explicit boolean
      when(() => mockDb.isOpen()).thenReturn(true);
      
      // Fix: Setup retrieving the music folder path
      when(() => mockDb.getValue('musicFolder')).thenAnswer((invocation) async {
        Result<String> successResult = Success('/storage/music');
        return successResult;
      });
          
      // Fix: Setup FileSystem returning NO files using manual list creation
      when(() => mockFs.getSongPaths('/storage/music')).thenAnswer((invocation) async {
        List<String> emptyList = [];
        Result<List<String>> successResult = Success(emptyList);
        return successResult;
      });
          
      // Fix: Setup DB returning old paths that need to be deleted
      when(() => mockDb.getSongPaths()).thenAnswer((invocation) async {
        List<String> oldPaths = [];
        oldPaths.add('/storage/music/old_song.mp3');
        Result<List<String>> successResult = Success(oldPaths);
        return successResult;
      });
          
      // Fix: Setup the DB deletion call
      when(() => mockDb.deleteSongs(songPaths: ['/storage/music/old_song.mp3'])).thenAnswer((invocation) async {
        Result<void> successResult = Success(unit);
        return successResult;
      });

      Result<void> result = await repository.scanFolder();

      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
      
      List<String> pathsToDelete = [];
      pathsToDelete.add('/storage/music/old_song.mp3');
      verify(() => mockDb.deleteSongs(songPaths: pathsToDelete)).called(1);
    });

    test('triggers setMusicFolder if the path is missing from DB', () async {
      when(() => mockDb.isOpen()).thenReturn(true);
      
      // Fix: First call throws to simulate missing key, second call succeeds after setMusicFolder
      int callCount = 0;
      when(() => mockDb.getValue('musicFolder')).thenAnswer((invocation) async {
        if (callCount == 0) {
          callCount = callCount + 1;
          throw Exception('Key not found');
        } else {
          callCount = callCount + 1;
          Result<String> successResult = Success('/storage/music');
          return successResult;
        }
      });

      // Fix: Mocks for the fallback setMusicFolder() call
      when(() => mockFs.getDirectoryPath()).thenAnswer((invocation) async {
        Result<String> successResult = Success('/storage/music');
        return successResult;
      });
      
      when(() => mockDb.insertKVPair('musicFolder', '/storage/music')).thenAnswer((invocation) async {
        Result<void> successResult = Success(unit);
        return successResult;
      });

      // Fix: Standard scan mocks
      when(() => mockFs.getSongPaths('/storage/music')).thenAnswer((invocation) async {
        List<String> emptyList = [];
        Result<List<String>> successResult = Success(emptyList);
        return successResult;
      });
      
      when(() => mockDb.getSongPaths()).thenAnswer((invocation) async {
        List<String> emptyList = [];
        Result<List<String>> successResult = Success(emptyList);
        return successResult;
      });
      
      when(() => mockDb.deleteSongs(songPaths: [])).thenAnswer((invocation) async {
        Result<void> successResult = Success(unit);
        return successResult;
      });

      Result<void> result = await repository.scanFolder();

      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
      
      // Fix: Verify setMusicFolder dependencies were hit
      verify(() => mockFs.getDirectoryPath()).called(1);
      verify(() => mockDb.insertKVPair('musicFolder', '/storage/music')).called(1);
    });
  });
}