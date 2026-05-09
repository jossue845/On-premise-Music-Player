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
      late final Directory directory;
      final List<File> files = [];

      if (!(await getStoragePermission())) {
        throw Exception("Storage permission not granted");
      }

      directory = Directory(directoryPath);

      files.addAll(
        directory.listSync(recursive: true).whereType<File>().toList(),
      );

      // Remove files that don't have an allowed extension.
      files.removeWhere((f) {
        for (final extension in _allowedMusicFileExtensions) {
          if (f.path.endsWith(".$extension")) {
            return false;
          }
        }
        return true;
      });

      return Success(files.map((f) => f.path).toList());
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Prompts the user to grant the permission to manage storage.
  ///
  /// Returns whether the permission is granted.
  Future<bool> getStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    return (await Permission.manageExternalStorage.request()).isGranted;
  }
}
