import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:result_dart/result_dart.dart';
import 'package:file_picker/file_picker.dart';

class FilesystemService {
  static const List<String> _musicFileExtensions = [
    "aac",
    "flac",
    "m4a",
    "mp3",
    "ogg",
    "opus",
    "wav",
  ];

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

  Future<Result<List<String>>> getSongPaths(List<String> directoryPaths) async {
    try {
      final List<Directory> directories = [];
      final List<File> files = [];

      if (!(await getStoragePermission())) {
        throw Exception("Storage permission not granted");
      }

      for (final path in directoryPaths) {
        directories.add(Directory(path));
      }

      for (final directory in directories) {
        files.addAll(
          directory.listSync(recursive: true).whereType<File>().toList(),
        );
      }

      files.removeWhere((f) {
        for (final extension in _musicFileExtensions) {
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

  Future<bool> getStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }
}
