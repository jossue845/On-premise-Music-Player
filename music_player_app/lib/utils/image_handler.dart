import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:result_dart/result_dart.dart';

mixin ImageHandler {
  Future<Result<String>> storePicture(
    Uint8List pictureBytes,
    DatabaseService database,
  ) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final digest = sha1.convert(pictureBytes);
      final filePath =
          "${tempDir.path}/flutter_music_player/img/${digest.toString()}.jpg";
      if (!database.isOpen()) {
        await database.open();
      }

      final bool imageAlreadyPresent = (await database.isImagePathPresent(
        filePath,
      )).getOrThrow();

      if (!imageAlreadyPresent) {
        File imageFile = await File(filePath).create(recursive: true);
        if (!JpegDecoder().isValidFile(pictureBytes)) {
          Image? img = decodeImage(pictureBytes);
          if (img == null) {
            throw Exception("Failed to get image");
          }
          imageFile.writeAsBytesSync(encodeJpg(img));
        } else {
          imageFile.writeAsBytesSync(pictureBytes);
        }
      }

      return Success(filePath);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
