import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:music_player_app/data/services/metadata_service.dart';

void main() {
  group('MetadataService Tests', () {
    
    test('Returns TheAudioDB artwork on success', () async {
      // Fix: mocknig the http client to intercpet the audiodb request
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('theaudiodb')) {
          return http.Response(
            jsonEncode({
              'album': [{'strAlbumThumb': 'https://fake-audiodb-link.com/image.jpg'}]
            }), 
            200
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = MetadataService(client: mockClient);
      final result = await service.fetchArtworkWithFallback('Test Song', 'Test Artist');

      expect(result, 'https://fake-audiodb-link.com/image.jpg');
    });

    test('Falls back to iTunes when TheAudioDB fails', () async {
      // Fix: forceing audiodb to reutrn null so the itunes fallback runs
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('theaudiodb')) {
          return http.Response(jsonEncode({'album': null}), 200);
        } else if (request.url.toString().contains('itunes')) {
          return http.Response(
            jsonEncode({
              'resultCount': 1,
              'results': [{'artworkUrl100': 'https://fake-itunes-link.com/100x100bb.jpg'}]
            }), 
            200
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = MetadataService(client: mockClient);
      final result = await service.fetchArtworkWithFallback('Test Song', 'Test Artist');

      // Fix: cheking if it actualy repalced the resolution string to 500x500
      expect(result, 'https://fake-itunes-link.com/500x500bb.jpg');
    });

    test('Returns null when both APIs fail', () async {
      // Fix: reterning empty results for both to see if it crahes
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('theaudiodb')) {
          return http.Response(jsonEncode({'album': null}), 200);
        } else if (request.url.toString().contains('itunes')) {
          return http.Response(jsonEncode({'resultCount': 0}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = MetadataService(client: mockClient);
      final result = await service.fetchArtworkWithFallback('Unknown Track', 'Unknown Artist');

      expect(result, isNull);
    });

    test('Handles server exceptions gracefully', () async {
      // Fix: simmulating a server crash to ensure the app stays alive
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('theaudiodb')) {
          return http.Response(jsonEncode({'album': null}), 200);
        }
        return http.Response('Internal Server Error', 500);
      });

      final service = MetadataService(client: mockClient);
      final result = await service.fetchArtworkWithFallback('Crash Track', 'Crash Artist');

      expect(result, isNull);
    });
  });
}