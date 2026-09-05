import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:result_dart/result_dart.dart';
import 'package:file_picker/file_picker.dart';

class FilesystemService {
  static const List<String> _allowedMusicFileExtensions = [
    "aac",
    "flac",
    "m4a",
    "mp3",
    "ogg",
    "opus",
    "wav",
  ];

  // 1. Add a customizable function for testing
  final Future<String?> Function(String? dialogTitle) _filePickerFn;

  // 2. Default to the real FilePicker in production
  FilesystemService({
    Future<String?> Function(String? dialogTitle)? filePickerFn,
  }) : _filePickerFn = filePickerFn ?? ((title) => FilePicker.getDirectoryPath(dialogTitle: title));

  // Prompts the user to select the directory containing their music files.
  Future<Result<String>> getDirectoryPath() async {
    try {
      if (!(await getStoragePermission())) {
        throw Exception("Storage permission not granted");
      }

      // 3. Use the injected function instead of the hardcoded static method
      String? selectedDirectoryPath = await _filePickerFn("Select the music directory");

      if (selectedDirectoryPath == null) {
        throw Exception("No directory selected");
      }

      return Success(selectedDirectoryPath);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  // Returns the paths to the music files contained in [directoryPath]
  Future<Result<List<String>>> getSongPaths(String directoryPath) async {
    try {
      if (!(await getStoragePermission())) {
        throw Exception("Storage permission not granted");
      }

      final directory = Directory(directoryPath);
      
      // 4. Explicitly check if the directory exists before the stream swallows the error
      if (!await directory.exists()) {
        throw const FileSystemException("Directory does not exist");
      }

      final List<String> paths = [];

      final stream = directory.list(recursive: true, followLinks: false);
      await for (final entity in stream.handleError((e) {
        // swallow individual "permission denied" / broken entries
        // and keep scanning the rest of the tree
      })) {
        if (entity is File && _hasAllowedExtension(entity.path)) {
          paths.add(entity.path);
        }
      }

      return Success(paths);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  bool _hasAllowedExtension(String path) {
    final lower = path.toLowerCase();
    return _allowedMusicFileExtensions.any((ext) => lower.endsWith(".$ext"));
  }

  // Prompts the user to grant the permission to read audio files.
  Future<bool> getStoragePermission() async {
    if (Platform.isAndroid) {
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) return true;

      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;

      if (manageStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
        print('🔑 Permanently denied — opening settings');
        await openAppSettings();
      }
      
      return false;
    }
    
    return true; 
  }
}