import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:music_player_app/data/services/lrclib_service.dart';

void main() {
  group('LrcLibService Unit Tests', () {
    
    test('getLyrics returns Success with parsed data on 200 OK', () async {
      // 1. Arrange: Create a MockClient that intercepts the network call
      final mockClient = MockClient((request) async {
        // We define the exact fake JSON we want the API to "return"
        final jsonResponse = {
          'id': 12345,
          'trackName': 'Yellow',
          'artistName': 'Coldplay',
          'syncedLyrics': '[00:12.00] Look at the stars',
          'plainLyrics': 'Look at the stars'
        };
        
        // Return a successful 200 status code with our fake JSON
        return http.Response(jsonEncode(jsonResponse), 200);
      });

      // Inject the mock client into your service so it doesn't use the real internet
      final service = LrcLibService(client: mockClient);

      // 2. Act: Call the method being tested
      final result = await service.getLyrics('Yellow', 'Coldplay');

      // 3. Assert: Verify the outcome
      expect(result.isSuccess(), true);
      
      final data = result.getOrThrow();
      expect(data['trackName'], 'Yellow');
      expect(data['syncedLyrics'], '[00:12.00] Look at the stars');
    });

    test('getLyrics returns Failure on 500 Server Error', () async {
      // 1. Arrange: Simulate a server crash
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = LrcLibService(client: mockClient);

      // 2. Act
      final result = await service.getLyrics('Yellow', 'Coldplay');

      // 3. Assert: It should safely fail and catch the API error
      expect(result.isError(), true);
      expect(
        result.exceptionOrNull().toString(),
        contains('LRCLIB API Error: 500')
      );
    });

  });
}