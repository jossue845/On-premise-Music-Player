import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:result_dart/result_dart.dart';

class CoverArtArchiveService {
  static const String _baseUrl = 'https://coverartarchive.org';
  final http.Client _client;

  CoverArtArchiveService({http.Client? client}) : _client = client ?? http.Client();

  // Fetches the front cover image bytes for a given release-group MBID.
  Future<Result<Uint8List>> getFrontCover(String releaseGroupMbid) async {
    // The API endpoint specifically requests the "front" image of the release group
    final url = Uri.parse('$_baseUrl/release-group/$releaseGroupMbid/front');
    
    try {
      // Cover Art Archive heavily relies on 307 redirects to the Internet Archive's storage servers.
      // The default http.Client handles these redirects automatically.
      final response = await _client.get(url);
      
      if (response.statusCode == 200) {
        return Success(response.bodyBytes);
      } else {
        return Failure(Exception('Cover Art Archive Error: HTTP ${response.statusCode}'));
      }
    } catch (e) {
      return Failure(Exception('Failed to fetch cover art from archive: $e'));
    }
  }
}