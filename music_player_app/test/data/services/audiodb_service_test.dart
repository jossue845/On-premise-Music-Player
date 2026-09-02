import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:result_dart/result_dart.dart';

// Adjust this import to match your project's folder structure
import 'package:music_player_app/data/services/audiodb_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late AudioDbService service;

  setUpAll(() {
    // Required so mocktail can use any() with Uri parameters
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = AudioDbService(client: mockClient);
  });

  group('AudioDbService - searchTrack', () {
    test('cleans track and artist strings before constructing URL and returns Success', () async {
      final mockResponse = jsonEncode({
        'track': [{'strTrack': 'Test Track', 'strArtist': 'Test Artist'}]
      });

      when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(mockResponse, 200));

      // Pass intentionally messy strings to trigger the regex cleaning logic
      final result = await service.searchTrack(
        'Starlight (Live at Rome) [Remastered] - Radio Edit', 
        'Muse feat. Someone'
      );

      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow()['track'][0]['strTrack'], 'Test Track');

      // Capture the exact URL the service tried to request
      final captured = verify(() => mockClient.get(captureAny())).captured;
      final uri = captured.first as Uri;
      
      // Verify the URL query parameters were successfully cleaned up
      expect(uri.queryParameters['t'], 'Starlight');
      expect(uri.queryParameters['s'], 'Muse');
    });

    test('returns Failure on non-200 HTTP status code', () async {
      when(() => mockClient.get(any())).thenAnswer((_) async => http.Response('Not Found', 404));

      final result = await service.searchTrack('Song', 'Artist');

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('TheAudioDB API Error: 404'));
    });

    test('returns Failure when http client throws an exception', () async {
      when(() => mockClient.get(any())).thenThrow(Exception('No Internet Connection'));

      final result = await service.searchTrack('Song', 'Artist');

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('Failed to reach TheAudioDB'));
    });
  });

  group('AudioDbService - searchAlbum', () {
    test('returns Success on 200 status code', () async {
      final mockResponse = jsonEncode({
        'album': [{'idAlbum': '123', 'strAlbumThumb': 'http://image.com'}]
      });

      when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(mockResponse, 200));

      final result = await service.searchAlbum('Absolution', 'Muse');

      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow()['album'][0]['idAlbum'], '123');
      
      // Verify URL construction
      final captured = verify(() => mockClient.get(captureAny())).captured;
      final uri = captured.first as Uri;
      expect(uri.queryParameters['a'], 'Absolution');
      expect(uri.queryParameters['s'], 'Muse');
    });

    test('returns Failure on non-200 HTTP status code', () async {
      when(() => mockClient.get(any())).thenAnswer((_) async => http.Response('Server Error', 500));

      final result = await service.searchAlbum('Absolution', 'Muse');

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('TheAudioDB API Error: 500'));
    });

    test('returns Failure when http client throws an exception', () async {
      when(() => mockClient.get(any())).thenThrow(Exception('Connection Timeout'));

      final result = await service.searchAlbum('Absolution', 'Muse');

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('Failed to reach TheAudioDB'));
    });
  });
}