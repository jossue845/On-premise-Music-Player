import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MetadataService {
  final http.Client _client;

  // Fix: adedd depnedency injection so we can pass a mock client in our tests
  MetadataService({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> fetchArtworkWithFallback(String title, String artist) async {
    String? artworkUrl = await _fetchFromTheAudioDB(title, artist);
    
    if (artworkUrl == null || artworkUrl.isEmpty) {
      artworkUrl = await _fetchItunesArtworkFallback(title, artist);
    }
    
    return artworkUrl;
  }

  Future<String?> _fetchFromTheAudioDB(String title, String artist) async {
    try {
      final queryArtist = Uri.encodeComponent(artist);
      final queryAlbum = Uri.encodeComponent(title); 
      final url = Uri.parse('https://www.theaudiodb.com/api/v1/json/2/searchalbum.php?s=$queryArtist&a=$queryAlbum');
      
      final response = await _client.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final albums = data['album'] as List?;
        if (albums != null && albums.isNotEmpty) {
          return albums.first['strAlbumThumb'] as String?;
        }
      }
    } catch (e) {
      debugPrint("AUDIO DB CRASH: $e");
      return null;
    }
    return null;
  }

  Future<String?> _fetchItunesArtworkFallback(String title, String artist) async {
    try {
      final safeTitle = title.replaceAll(RegExp(r'\(.*\)'), '').trim();
      final safeArtist = artist.replaceAll(RegExp(r'feat\..*|ft\..*'), '').trim();
      
      final query = Uri.encodeComponent('$safeTitle $safeArtist');
      final url = Uri.parse('https://itunes.apple.com/search?term=$query&entity=song&limit=1');
      
      final response = await _client.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)'
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          final String artwork = data['results'][0]['artworkUrl100'];
          return artwork.replaceAll('100x100bb', '500x500bb');
        }
      }
    } catch (e) {
      debugPrint("ITUNES CRASH: $e");
      return null;
    }
    return null;
  }
}