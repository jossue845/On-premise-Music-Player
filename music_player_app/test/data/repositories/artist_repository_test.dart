import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

// Adjust these imports to match your project's folder structure
import 'package:music_player_app/data/repositories/artist_repository.dart'; // Adjust path
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/artist/artist.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockArtist extends Mock implements Artist {}

void main() {
  late MockDatabaseService mockDatabaseService;
  late ArtistRepository artistRepository;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    artistRepository = ArtistRepository(database: mockDatabaseService);
  });

  group('ArtistRepository Tests', () {
    final mockArtists = [MockArtist(), MockArtist()];

    test('getArtists() opens the database if it is closed and returns artists', () async {
      // Arrange
      when(() => mockDatabaseService.isOpen()).thenReturn(false);
      when(() => mockDatabaseService.open()).thenAnswer((_) async {}); // Assuming open() returns Future<void>
      when(() => mockDatabaseService.getArtists())
          .thenAnswer((_) async => Success(mockArtists));

      // Act
      final result = await artistRepository.getArtists();

      // Assert
      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow(), equals(mockArtists));
      
      verify(() => mockDatabaseService.isOpen()).called(1);
      verify(() => mockDatabaseService.open()).called(1);
      verify(() => mockDatabaseService.getArtists()).called(1);
    });

    test('getArtists() skips opening if the database is already open', () async {
      // Arrange
      when(() => mockDatabaseService.isOpen()).thenReturn(true);
      when(() => mockDatabaseService.getArtists())
          .thenAnswer((_) async => Success(mockArtists));

      // Act
      final result = await artistRepository.getArtists();

      // Assert
      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow(), equals(mockArtists));
      
      verify(() => mockDatabaseService.isOpen()).called(1);
      verifyNever(() => mockDatabaseService.open());
      verify(() => mockDatabaseService.getArtists()).called(1);
    });

    test('getArtists() returns a Failure if the database service fails', () async {
      // Arrange
      final fakeException = Exception('Database crash');
      when(() => mockDatabaseService.isOpen()).thenReturn(true);
      when(() => mockDatabaseService.getArtists())
          .thenAnswer((_) async => Failure(fakeException));

      // Act
      final result = await artistRepository.getArtists();

      // Assert
      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull(), equals(fakeException));
      
      verify(() => mockDatabaseService.getArtists()).called(1);
    });
  });
}