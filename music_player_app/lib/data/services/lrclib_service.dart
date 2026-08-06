import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:result_dart/result_dart.dart';

class LrcLibService {
  static const String _baseUrl = 'https://lrclib.net/api';
  final http.Client _client;

  LrcLibService({http.Client? client}) : _client = client ?? http.Client();

  // LRCLIB strictly requires a descriptive User-Agent to prevent rate-limiting or 403 blocks.
  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'User-Agent': 'DIMAMusicPlayer/1.0.0',
      };

  /// Attempts an exact match fetch for synced or plain lyrics.
  Future<Result<Map<String, dynamic>>> getLyrics(
    String trackName,
    String artistName, {
    String? albumName,
    int? durationInSeconds,
  }) async {
    debugPrint('🟢 getLyrics() ENTERED: track=$trackName artist=$artistName');

    final queryParams = <String, String>{
      'track_name': trackName,
      'artist_name': artistName,
    };

    if (albumName != null && albumName.isNotEmpty && albumName != 'Unknown Album') {
      queryParams['album_name'] = albumName;
    }
    if (durationInSeconds != null && durationInSeconds > 0) {
      queryParams['duration'] = durationInSeconds.toString();
    }

    final uri = Uri.parse('$_baseUrl/get').replace(queryParameters: queryParams);

    debugPrint('🟢 About to GET: $uri');

    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('🟢 Got response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return Success(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        debugPrint('🟢 404 on exact match, falling back to search');
        return _searchLyrics(trackName, artistName);
      } else {
        return Failure(Exception('LRCLIB API Error: ${response.statusCode}'));
      }
    } catch (e, st) {
      debugPrint('🔴 getLyrics() CAUGHT: $e');
      debugPrint('🔴 STACK:\n$st');
      return Failure(Exception('Failed to reach LRCLIB: $e'));
    }
  }

  /// Fallback method executing a broad search query if the exact endpoint fails.
  Future<Result<Map<String, dynamic>>> _searchLyrics(String trackName, String artistName) async {
    debugPrint('🟢 _searchLyrics() ENTERED: track=$trackName artist=$artistName');

    final queryParams = <String, String>{
      'track_name': trackName,
      'artist_name': artistName,
    };

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: queryParams);

    debugPrint('🟢 About to GET (search): $uri');

    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('🟢 Got search response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          return Success(results.first as Map<String, dynamic>);
        } else {
          return Failure(Exception('No lyrics found for this track.'));
        }
      } else {
        return Failure(Exception('LRCLIB Search API Error: ${response.statusCode}'));
      }
    } catch (e, st) {
      debugPrint('🔴 _searchLyrics() CAUGHT: $e');
      debugPrint('🔴 STACK:\n$st');
      return Failure(Exception('Failed to search LRCLIB: $e'));
    }
  }
}