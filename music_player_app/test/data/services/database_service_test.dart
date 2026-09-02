import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Adjust this import to match your project's folder structure
import 'package:music_player_app/data/services/filesystem_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late FilesystemService service;
  late Directory tempDir;

  setUp(() {
    service = FilesystemService();
    // Create a real temporary directory on the host machine for scanning tests
    tempDir = Directory.systemTemp.createTempSync('fs_test_');

    // Intercept the permission_handler native channel to simulate granted permissions
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'requestPermissions') {
          // '1' represents PermissionStatus.granted
          final List<dynamic> requestedPermissions = methodCall.arguments;
          return {for (var permission in requestedPermissions) permission: 1};
        }
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; 
        }
        return null;
      },
    );

    // Intercept the FilePicker native channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('miguelruivo.flutter.plugins.filepicker'),
      (MethodCall methodCall) async {
        // Handle both 'dir' (used by Android) and 'getDirectoryPath'
        if (methodCall.method == 'dir' || methodCall.method == 'getDirectoryPath') {
          return tempDir.path;
        }
        return null;
      },
    );
  });

  tearDown(() {
    // Clean up the physical temporary files after each test
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    
    // Clear both channel mocks
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('miguelruivo.flutter.plugins.filepicker'),
      null,
    );
  });

  group('FilesystemService - Directory Selection', () {
    test('getDirectoryPath returns Success with path when user selects a directory', () async {
      final result = await service.getDirectoryPath();
      
      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow(), tempDir.path);
    });

    test('getDirectoryPath returns Failure when user cancels selection', () async {
      // Override the mock to simulate the user pressing "Cancel"
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('miguelruivo.flutter.plugins.filepicker'),
        (MethodCall methodCall) async => null,
      );

      final result = await service.getDirectoryPath();
      
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('No directory selected'));
    });
  });

  group('FilesystemService - File Scanning', () {
    test('getSongPaths recursively finds allowed audio files and ignores others', () async {
      // 1. Arrange: Create a nested directory structure with mixed file types
      final subDir = Directory('${tempDir.path}/sub_folder')..createSync();
      
      File('${tempDir.path}/song1.mp3').createSync();
      File('${tempDir.path}/song2.FLAC').createSync(); // Validates case-insensitivity
      File('${tempDir.path}/notes.txt').createSync();  // Should be ignored
      File('${subDir.path}/song3.wav').createSync();   // Validates recursive scanning
      File('${subDir.path}/cover.jpg').createSync();   // Should be ignored

      // 2. Act: Scan the temporary directory
      final result = await service.getSongPaths(tempDir.path);

      // 3. Assert: Verify only the 3 audio files were captured
      expect(result.isSuccess(), isTrue);
      final paths = result.getOrThrow();

      expect(paths.length, 3);
      expect(paths.any((p) => p.endsWith('song1.mp3')), isTrue);
      expect(paths.any((p) => p.endsWith('song2.FLAC')), isTrue);
      expect(paths.any((p) => p.endsWith('song3.wav')), isTrue);
    });

    test('getSongPaths returns Failure if directory does not exist', () async {
      // Pass a garbage path that forces a FileSystemException
      final result = await service.getSongPaths('/this/path/does/not/exist/12345');
      
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull(), isA<FileSystemException>());
    });
  });
}