import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:result_dart/result_dart.dart';

// Adjust this import to match your project's folder structure
import 'package:music_player_app/data/services/cover_art_archive_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late CoverArtArchiveService service;

  setUpAll(() {
    // Required so mocktail can use any() with Uri parameters
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = CoverArtArchiveService(client: mockClient);
  });

  group('CoverArtArchiveService Tests', () {
    
    test('getFrontCover returns Success with image bytes on 200 OK', () async {
      // Arrange
      final fakeImageBytes = Uint8List.fromList([10, 20, 30, 40]);
      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response.bytes(fakeImageBytes, 200));

      // Act
      final result = await service.getFrontCover('fake-mbid-1234');

      // Assert
      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow(), equals(fakeImageBytes));

      // Verify the correct URL was constructed
      final captured = verify(() => mockClient.get(captureAny())).captured;
      final uri = captured.first as Uri;
      expect(uri.toString(), 'https://coverartarchive.org/release-group/fake-mbid-1234/front');
    });

    test('getFrontCover returns Failure on non-200 HTTP status code', () async {
      // Arrange
      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      // Act
      final result = await service.getFrontCover('fake-mbid-1234');

      // Assert
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('Cover Art Archive Error: HTTP 404'));
    });

    test('getFrontCover returns Failure when HTTP client throws an exception', () async {
      // Arrange
      when(() => mockClient.get(any()))
          .thenThrow(Exception('Network timeout'));

      // Act
      final result = await service.getFrontCover('fake-mbid-1234');

      // Assert
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('Failed to fetch cover art from archive'));
    });
  });
}