import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_player_app/domain/models/scrobble/scrobble.dart';

// 1. Expose the service via a Riverpod Provider
final lastFmServiceProvider = Provider<LastFmService>((ref) {
  return LastFmService(
    apiKey: dotenv.env['LASTFM_API_KEY'] ?? '',
    apiSecret: dotenv.env['LASTFM_API_SECRET'] ?? '',
  );
});

// 2. The core service class
class LastFmService {
  static const String _apiUrl = 'https://ws.audioscrobbler.com/2.0/';
  final String apiKey;
  final String apiSecret;

  LastFmService({required this.apiKey, required this.apiSecret});

  // Private method: Generates the mandatory MD5 signature for write requests
  String _generateSignature(Map<String, String> params) {
    final sortedKeys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    
    for (final key in sortedKeys) {
      if (key != 'format' && key != 'callback') {
        buffer.write(key);
        buffer.write(params[key]);
      }
    }
    
    buffer.write(apiSecret);
    final bytes = utf8.encode(buffer.toString());
    return md5.convert(bytes).toString();
  }

  // Public method: Authenticates the user and retrieves the offline session key
  Future<String?> authenticate(String username, String password) async {
    final params = {
      'method': 'auth.getMobileSession',
      'username': username,
      'password': password,
      'api_key': apiKey,
    };
    
    params['api_sig'] = _generateSignature(params);
    params['format'] = 'json';
    
    try {
      final response = await http.post(Uri.parse(_apiUrl), body: params);
      final data = json.decode(response.body);
      
      // Check if Last.fm returned a specific API error message
      if (data.containsKey('error')) {
        final errorMessage = data['message'] ?? 'Authentication failed';
        throw Exception(errorMessage); // This is caught by Riverpod and shown in the SnackBar
      }
      
      if (response.statusCode == 200 && data['session'] != null) {
        return data['session']['key'];
      } else {
        throw Exception('Unexpected server response');
      }
    } catch (e) {
      // Rethrow to ensure the UI's AsyncValue captures the exact error string
      rethrow; 
    }
  }

  // Updates the user's Last.fm profile with a "Now Playing" status.
  // This should be called immediately when a track starts playing.
  Future<void> updateNowPlaying(Scrobble scrobble, String sessionKey) async {
    final params = <String, String>{
      'method': 'track.updateNowPlaying',
      'artist': scrobble.artist,
      'track': scrobble.track,
      'api_key': apiKey,
      'sk': sessionKey,
    };

    if (scrobble.album != null && scrobble.album!.isNotEmpty) {
      params['album'] = scrobble.album!;
    }

    // Generate the signature before adding the 'format' parameter
    params['api_sig'] = _generateSignature(params);
    params['format'] = 'json';

    final response = await http.post(Uri.parse(_apiUrl), body: params);
    final data = json.decode(response.body);

    if (data.containsKey('error')) {
      throw Exception(data['message'] ?? 'Failed to update now playing status');
    }
  }

  // Submits completed scrobbles to Last.fm.
  // Accepts a list to support batch uploading from the local database cache.
  Future<void> scrobble(List<Scrobble> scrobbles, String sessionKey) async {
    if (scrobbles.isEmpty) return;

    final params = <String, String>{
      'method': 'track.scrobble',
      'api_key': apiKey,
      'sk': sessionKey,
    };

    // Format parameters using array notation for batch processing
    // Note: The maximum batch size supported by Last.fm is 50 tracks.
    for (int i = 0; i < scrobbles.length; i++) {
      final s = scrobbles[i];
      params['artist[$i]'] = s.artist;
      params['track[$i]'] = s.track;
      params['timestamp[$i]'] = s.timestamp.toString();
      
      if (s.album != null && s.album!.isNotEmpty) {
        params['album[$i]'] = s.album!;
      }
    }

    params['api_sig'] = _generateSignature(params);
    params['format'] = 'json';

    final response = await http.post(Uri.parse(_apiUrl), body: params);
    final data = json.decode(response.body);

    if (data.containsKey('error')) {
      throw Exception(data['message'] ?? 'Failed to submit scrobbles');
    }
  }
}