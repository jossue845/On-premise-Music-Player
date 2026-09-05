import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

// Fix: Adjust this import to match the project's folder structure
import 'package:music_player_app/data/services/filesystem_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late FilesystemService service;
  late Directory tempDir;
  String? mockedDirectoryResponse;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fs_test_');
    mockedDirectoryResponse = tempDir.path;
    
    // Fix: Inject our dummy function directly into the service using explicit types
    service = FilesystemService(
      filePickerFn: (String? dialogTitle) async {
        return mockedDirectoryResponse;
      },
    );

    // Fix: We still keep the permission_handler mock because it is a clean native channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'requestPermissions') {
          List<dynamic> requestedPermissions = methodCall.arguments;
          
          Map<dynamic, int> permissionMap = Map<dynamic, int>();
          for (int i = 0; i < requestedPermissions.length; i++) {
            dynamic permission = requestedPermissions[i];
            permissionMap[permission] = 1;
          }
          
          return permissionMap;
        }
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; 
        }
        return null;
      },
    );
  });

  tearDown(() {
    bool doesDirExist = false;
    if (tempDir.existsSync() == true) {
      doesDirExist = true;
    }
    
    if (doesDirExist == true) {
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
      Result<String> result = await service.getDirectoryPath();
      
      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
      expect(result.getOrThrow(), tempDir.path);
    });

    test('getDirectoryPath returns Failure when user cancels selection', () async {
      // Fix: Alter the injected function's return value to simulate cancellation
      mockedDirectoryResponse = null;

      Result<String> result = await service.getDirectoryPath();
      
      bool isError = false;
      if (result.isError() == true) {
        isError = true;
      }
      expect(isError, true);
      
      String errorString = result.exceptionOrNull().toString();
      bool containsErrorText = false;
      if (errorString.contains('No directory selected') == true) {
        containsErrorText = true;
      }
      expect(containsErrorText, true);
    });
  });

  group('FilesystemService - File Scanning', () {
    test('getSongPaths recursively finds allowed audio files and ignores others', () async {
      Directory subDir = Directory('${tempDir.path}/sub_folder');
      subDir.createSync();
      
      File song1 = File('${tempDir.path}/song1.mp3');
      song1.createSync();
      
      File song2 = File('${tempDir.path}/song2.FLAC');
      song2.createSync(); 
      
      File notes = File('${tempDir.path}/notes.txt');
      notes.createSync();  
      
      File song3 = File('${subDir.path}/song3.wav');
      song3.createSync();   
      
      File cover = File('${subDir.path}/cover.jpg');
      cover.createSync();   

      Result<List<String>> result = await service.getSongPaths(tempDir.path);

      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
      
      List<String> paths = result.getOrThrow();
      expect(paths.length, 3);
      
      bool hasSong1 = false;
      bool hasSong2 = false;
      bool hasSong3 = false;
      
      for (int i = 0; i < paths.length; i++) {
        String currentPath = paths[i];
        if (currentPath.endsWith('song1.mp3') == true) {
          hasSong1 = true;
        }
        if (currentPath.endsWith('song2.FLAC') == true) {
          hasSong2 = true;
        }
        if (currentPath.endsWith('song3.wav') == true) {
          hasSong3 = true;
        }
      }
      
      expect(hasSong1, true);
      expect(hasSong2, true);
      expect(hasSong3, true);
    });

    test('getSongPaths returns Failure if directory does not exist', () async {
      Result<List<String>> result = await service.getSongPaths('/this/path/does/not/exist/12345');
      
      bool isError = false;
      if (result.isError() == true) {
        isError = true;
      }
      expect(isError, true);
      expect(result.exceptionOrNull(), isA<FileSystemException>());
    });
  });
}