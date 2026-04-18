import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:result_dart/result_dart.dart';
import 'package:file_picker/file_picker.dart';

class FilesystemService {
  Future<Result<List<String>>> getSongPaths() async {
    try {
      await getStoragePermission();

      String? selectedDirectoryPath = await FilePicker.getDirectoryPath(
        dialogTitle: "Select the music directory",
      );

      if (selectedDirectoryPath == null) {
        throw Exception("No directory selected");
      }

      final directory = Directory(selectedDirectoryPath);
      final files = directory
          .listSync(recursive: true)
          .whereType<File>()
          .toList();

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
