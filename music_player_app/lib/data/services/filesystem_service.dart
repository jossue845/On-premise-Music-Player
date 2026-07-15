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

  /// Prompts the user to select the directory containing their music files.
  ///
  /// Returns the path to the directory.
  Future<Result<String>> getDirectoryPath() async {
    try {
      if (!(await getStoragePermission())) {
        throw Exception("Storage permission not granted");
      }

      String? selectedDirectoryPath = await FilePicker.getDirectoryPath(
        dialogTitle: "Select the music directory",
      );

      if (selectedDirectoryPath == null) {
        throw Exception("No directory selected");
      }

      return Success(selectedDirectoryPath);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Returns the paths to the music files contained in [directoryPath]
  Future<Result<List<String>>> getSongPaths(String directoryPath) async {
    try {
      if (!(await getStoragePermission())) {
        throw Exception("Storage permission not granted");
      }

      final directory = Directory(directoryPath);
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

  /// Prompts the user to grant the permission to read audio files.
  ///
  /// Returns whether the permission is granted.
  Future<bool> getStoragePermission() async {
    if (Platform.isAndroid) {
      // 1. Request All Files Access (Required for Directory.list() to work on modern Android)
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) return true;

      // 2. Fallback for older Android versions
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      // 3. Fallback for strict audio permissions
      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;

      // If everything fails, send them to settings
      if (manageStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
        print('🔑 Permanently denied — opening settings');
        await openAppSettings();
      }
      
      return false;
    }
    
    return true; // Default to true for non-Android platforms during dev
  }
}