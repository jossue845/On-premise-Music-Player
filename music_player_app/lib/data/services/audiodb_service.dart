import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:result_dart/result_dart.dart';

class AudioDbService {
  // Using '2' which is the standard public tier API key for TheAudioDB
  static const String _baseUrl = 'https://www.theaudiodb.com/api/v1/json/2';
  final http.Client _client;

  AudioDbService({http.Client? client}) : _client = client ?? http.Client();

  // Fix: Removed emojis from debug outputs and applied explicit boolean validation
  Future<Result<Map<String, dynamic>>> searchTrack(String trackTitle, String artistName) async {
    // Aggressive String Cleaning
    String cleanTitle = trackTitle.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    cleanTitle = cleanTitle.replaceAll(RegExp(r'\[[^\]]*\]'), '').trim();
    cleanTitle = cleanTitle.split(' - ').first.trim();

    String cleanArtist = artistName.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    cleanArtist = cleanArtist.split(' feat').first.trim();

    final url = Uri.parse('$_baseUrl/searchtrack.php?s=${Uri.encodeComponent(cleanArtist)}&t=${Uri.encodeComponent(cleanTitle)}');
    debugPrint('THEAUDIODB URL: $url'); 

    try {
      final response = await _client.get(url);
      
      bool isSuccess = false;
      if (response.statusCode == 200) {
        isSuccess = true;
      }
      
      if (isSuccess == true) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tracks = data['track'] as List?;
        
        bool hasTracks = false;
        if (tracks != null) {
          if (tracks.isNotEmpty == true) {
            hasTracks = true;
          }
        }
        
        if (hasTracks == true) {
          debugPrint('THEAUDIODB TOP MATCH: ${tracks!.first['strTrack']}');
        } else {
          debugPrint('THEAUDIODB RETURNED 0 RESULTS');
        }
        
        return Success(data);
      } else {
        debugPrint('THEAUDIODB HTTP ERROR: ${response.statusCode}'); 
        return Failure(Exception('TheAudioDB API Error: ${response.statusCode}'));
      }
    } catch (e) {
      debugPrint('THEAUDIODB EXCEPTION: $e');
      return Failure(Exception('Failed to reach TheAudioDB: $e'));
    }
  }

  // Searches for an album to retrieve artwork using concise ternary logic
  Future<Result<Map<String, dynamic>>> searchAlbum(String albumTitle, String artistName) async {
    final url = Uri.parse('$_baseUrl/searchalbum.php?s=${Uri.encodeComponent(artistName)}&a=${Uri.encodeComponent(albumTitle)}');
    try {
      final response = await _client.get(url);
      return response.statusCode == 200 
          ? Success(jsonDecode(response.body) as Map<String, dynamic>) 
          : Failure(Exception('TheAudioDB API Error: ${response.statusCode}'));
    } catch (e) {
      return Failure(Exception('Failed to reach TheAudioDB: $e'));
    }
  }
}