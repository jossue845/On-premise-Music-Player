import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:result_dart/result_dart.dart';

class MusicBrainzService {
  static const String _baseUrl = 'https://musicbrainz.org/ws/2';
  final http.Client _client;

  MusicBrainzService({http.Client? client}) : _client = client ?? http.Client();

  // MusicBrainz requires a descriptive User-Agent header; requests without one are often blocked (HTTP 403).
  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'User-Agent': 'DIMAMusicPlayer/1.0.0', 
      };

  /// Searches for an artist by name using Lucene syntax.
  Future<Result<Map<String, dynamic>>> searchArtist(String artistName) async {
    // Appending fmt=json is strictly required as the API defaults to XML format.
    final url = Uri.parse('$_baseUrl/artist/?query=artist:${Uri.encodeComponent(artistName)}&fmt=json');
    
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return Success(jsonDecode(response.body));
      } else {
        return Failure(Exception('MusicBrainz API Error: ${response.statusCode}'));
      }
    } catch (e) {
      return Failure(Exception('Failed to reach MusicBrainz: $e'));
    }
  }

  /// Searches for an album (release-group) by title and artist.
  Future<Result<Map<String, dynamic>>> searchAlbum(String albumTitle, String artistName) async {
    // Utilizing Lucene search syntax to target multiple fields simultaneously.
    final query = 'releasegroup:${Uri.encodeComponent(albumTitle)} AND artist:${Uri.encodeComponent(artistName)}';
    final url = Uri.parse('$_baseUrl/release-group/?query=$query&fmt=json');
    
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return Success(jsonDecode(response.body));
      } else {
        return Failure(Exception('MusicBrainz API Error: ${response.statusCode}'));
      }
    } catch (e) {
      return Failure(Exception('Failed to reach MusicBrainz: $e'));
    }
  }

  /// Retrieves detailed metadata for a specific entity using its MusicBrainz ID (MBID).
  Future<Result<Map<String, dynamic>>> lookupEntity(String entityType, String mbid, {List<String> includes = const []}) async {
    // The 'inc' parameter allows batching linked entities like recordings or labels into the response.
    final incParam = includes.isNotEmpty ? '&inc=${includes.join('+')}' : '';
    final url = Uri.parse('$_baseUrl/$entityType/$mbid?fmt=json$incParam');
    
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return Success(jsonDecode(response.body));
      } else {
        return Failure(Exception('MusicBrainz API Error: ${response.statusCode}'));
      }
    } catch (e) {
      return Failure(Exception('Failed to reach MusicBrainz: $e'));
    }
  }
}