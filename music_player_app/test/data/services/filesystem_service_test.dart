import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Adjust this import to match your project's folder structure
import 'package:music_player_app/data/services/filesystem_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late FilesystemService service;
  late Directory tempDir;
  String? mockedDirectoryResponse;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fs_test_');
    mockedDirectoryResponse = tempDir.path;
    
    // Inject our dummy function directly into the service
    service = FilesystemService(
      filePickerFn: (String? dialogTitle) async => mockedDirectoryResponse,
    );

    // We still keep the permission_handler mock because it is a clean native channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'requestPermissions') {
          final List<dynamic> requestedPermissions = methodCall.arguments;
          return {for (var permission in requestedPermissions) permission: 1};
        }
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; 
        }
        return null;
      },
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
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
      // Alter the injected function's return value to simulate cancellation
      mockedDirectoryResponse = null;

      final result = await service.getDirectoryPath();
      
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('No directory selected'));
    });
  });

  group('FilesystemService - File Scanning', () {
    test('getSongPaths recursively finds allowed audio files and ignores others', () async {
      final subDir = Directory('${tempDir.path}/sub_folder')..createSync();
      
      File('${tempDir.path}/song1.mp3').createSync();
      File('${tempDir.path}/song2.FLAC').createSync(); 
      File('${tempDir.path}/notes.txt').createSync();  
      File('${subDir.path}/song3.wav').createSync();   
      File('${subDir.path}/cover.jpg').createSync();   

      final result = await service.getSongPaths(tempDir.path);

      expect(result.isSuccess(), isTrue);
      final paths = result.getOrThrow();

      expect(paths.length, 3);
      expect(paths.any((p) => p.endsWith('song1.mp3')), isTrue);
      expect(paths.any((p) => p.endsWith('song2.FLAC')), isTrue);
      expect(paths.any((p) => p.endsWith('song3.wav')), isTrue);
    });

    test('getSongPaths returns Failure if directory does not exist', () async {
      final result = await service.getSongPaths('/this/path/does/not/exist/12345');
      
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull(), isA<FileSystemException>());
    });
  });
}