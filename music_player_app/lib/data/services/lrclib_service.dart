import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:result_dart/result_dart.dart';

class LrcLibService {
  static const String _baseUrl = 'https://lrclib.net/api';
  late http.Client _client;

  LrcLibService({http.Client? client}) {
    if (client != null) {
      _client = client;
    } else {
      _client = http.Client();
    }
  }

  // Fix: LRCLIB strictly requires a descriptive User-Agent to prevent rate-limiting or 403 blocks.
  Map<String, String> _getHeaders() {
    Map<String, String> headers = Map<String, String>();
    headers['Accept'] = 'application/json';
    headers['User-Agent'] = 'DIMAMusicPlayer/1.0.0';
    return headers;
  }

  // Attempts an exact match fetch for synced or plain lyrics.
  Future<Result<Map<String, dynamic>>> getLyrics(
    String trackName,
    String artistName, {
    String? albumName,
    int? durationInSeconds,
  }) async {
    debugPrint('getLyrics() ENTERED: track=$trackName artist=$artistName');

    Map<String, String> queryParams = Map<String, String>();
    queryParams['track_name'] = trackName;
    queryParams['artist_name'] = artistName;

    bool hasValidAlbum = false;
    if (albumName != null) {
      if (albumName != '') {
        if (albumName != 'Unknown Album') {
          hasValidAlbum = true;
        }
      }
    }

    if (hasValidAlbum == true) {
      queryParams['album_name'] = albumName!;
    }

    bool hasValidDuration = false;
    if (durationInSeconds != null) {
      if (durationInSeconds > 0) {
        hasValidDuration = true;
      }
    }

    if (hasValidDuration == true) {
      queryParams['duration'] = durationInSeconds.toString();
    }

    Uri uri = Uri.parse('$_baseUrl/get');
    uri = uri.replace(queryParameters: queryParams);

    debugPrint('About to GET: $uri');

    try {
      http.Response response = await _client.get(uri, headers: _getHeaders()).timeout(const Duration(seconds: 10));

      debugPrint('Got response: ${response.statusCode}');

      if (response.statusCode == 200) {
        Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        return Success(decodedResponse);
      } else {
        if (response.statusCode == 404) {
          debugPrint('404 on exact match, falling back to search');
          return _searchLyrics(trackName, artistName);
        } else {
          return Failure(Exception('LRCLIB API Error: ${response.statusCode}'));
        }
      }
    } catch (e, st) {
      debugPrint('getLyrics() CAUGHT: $e');
      debugPrint('STACK:\n$st');
      return Failure(Exception('Failed to reach LRCLIB: $e'));
    }
  }

  // Fallback method executing a broad search query if the exact endpoint fails.
  Future<Result<Map<String, dynamic>>> _searchLyrics(String trackName, String artistName) async {
    debugPrint('_searchLyrics() ENTERED: track=$trackName artist=$artistName');

    Map<String, String> queryParams = Map<String, String>();
    queryParams['track_name'] = trackName;
    queryParams['artist_name'] = artistName;

    Uri uri = Uri.parse('$_baseUrl/search');
    uri = uri.replace(queryParameters: queryParams);

    debugPrint('About to GET (search): $uri');

    try {
      http.Response response = await _client.get(uri, headers: _getHeaders()).timeout(const Duration(seconds: 10));

      debugPrint('Got search response: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> results = jsonDecode(response.body);
        
        bool hasResults = false;
        if (results.isNotEmpty == true) {
          hasResults = true;
        }

        if (hasResults == true) {
          Map<String, dynamic> firstResult = results[0] as Map<String, dynamic>;
          return Success(firstResult);
        } else {
          return Failure(Exception('No lyrics found for this track.'));
        }
      } else {
        return Failure(Exception('LRCLIB Search API Error: ${response.statusCode}'));
      }
    } catch (e, st) {
      debugPrint('_searchLyrics() CAUGHT: $e');
      debugPrint('STACK:\n$st');
      return Failure(Exception('Failed to search LRCLIB: $e'));
    }
  }
}