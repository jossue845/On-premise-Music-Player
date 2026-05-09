import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:result_dart/result_dart.dart';

class TagUtils {
  /// Stores the provided [pictureBytes] in the local app folder.
  ///
  /// Returns the image path.
  static Future<Result<String>> storePicture(Uint8List pictureBytes) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final digest = sha1.convert(pictureBytes); // Hash the image
      final filePath = "${tempDir.path}/img/${digest.toString()}.jpg";
      final Directory imageDir = Directory("${tempDir.path}/img");
      final File imageFile = File(filePath);

      if (!imageDir.existsSync()) {
        imageDir.createSync(recursive: true);
      }

      if (!imageFile.existsSync()) {
        imageFile.createSync(recursive: true);
        // If the provided image isn't a jpeg, convert it.
        if (!JpegDecoder().isValidFile(pictureBytes)) {
          Image? img = decodeImage(pictureBytes);
          if (img == null) {
            throw Exception("Failed to convert image");
          }
          imageFile.writeAsBytesSync(encodeJpg(img));
        } else {
          imageFile.writeAsBytesSync(pictureBytes);
        }
      }

      return Success(filePath);
    } on Exception catch (e) {
      stderr.writeln(e);
      return Failure(Exception("Failed to store picture."));
    }
  }

  /// Parse [artistsString], a string containing multiple artists separated by ";" or "/", and return the artists as a list.
  static List<String> parseArtists(String artistsString) {
    List<String> artists = artistsString.split(RegExp(r"[;/]"));
    return artists.map((a) => a.trim()).toList();
  }
}
