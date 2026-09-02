import 'dart:collection';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';
import 'package:http/http.dart' as http;

// Adjust imports to match your project
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/services/audiodb_service.dart';
import 'package:music_player_app/data/services/lrclib_service.dart';
import 'package:music_player_app/domain/models/song/song.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockAudioDbService extends Mock implements AudioDbService {}
class MockLrcLibService extends Mock implements LrcLibService {}
class MockHttpClient extends Mock implements http.Client {}

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();
  
  late MockDatabaseService mockDb;
  late MockAudioDbService mockAudioDb;
  late MockLrcLibService mockLrcLib;
  late MockHttpClient mockHttp;
  late SongRepository repository;

  final dummySong = Song(
    id: 1,
    title: 'Test Song',
    album: 'Test Album',
    albumId: 1,
    artists: UnmodifiableListView(['Test Artist']),
    path: '/fake/path/song.mp3',
    favorite: false,
  );

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
    registerFallbackValue(dummySong);
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockAudioDb = MockAudioDbService();
    mockLrcLib = MockLrcLibService();
    mockHttp = MockHttpClient();

    repository = SongRepository(
      database: mockDb,
      audioDbService: mockAudioDb,
      lrcLibService: mockLrcLib,
      httpClient: mockHttp,
    );

    when(() => mockDb.isOpen()).thenReturn(true);
  });

  group('SongRepository - Database Delegation Tests', () {
    test('getSongs delegates correctly to database service', () async {
      when(() => mockDb.getSongs(albumId: any(named: 'albumId'), artistId: null, playlistId: null))
          .thenAnswer((_) async => Success([dummySong]));

      final result = await repository.getSongs(albumId: 5);

      expect(result.isSuccess(), isTrue);
      verify(() => mockDb.getSongs(albumId: 5, artistId: null, playlistId: null)).called(1);
    });

    test('incrementPlayCount delegates to database', () async {
      when(() => mockDb.incrementPlayCount(1)).thenAnswer((_) async => const Success(unit));

      final result = await repository.incrementPlayCount(1);
      expect(result.isSuccess(), isTrue);
    });

    test('setFavoriteStatus delegates to database', () async {
      when(() => mockDb.setFavoriteStatus(1, true)).thenAnswer((_) async => const Success(unit));

      final result = await repository.setFavoriteStatus(1, true);
      expect(result.isSuccess(), isTrue);
    });
  });

  group('SongRepository - API Service Logic Tests', () {
    test('fetchAndSaveLyrics updates DB when lyrics are found', () async {
      when(() => mockLrcLib.getLyrics('Test Song', 'Test Artist', albumName: 'Test Album'))
          .thenAnswer((_) async => const Success({'syncedLyrics': 'Test synced lyrics', 'plainLyrics': null}));
      
      when(() => mockDb.updateSong(any())).thenAnswer((_) async => 1);

      final result = await repository.fetchAndSaveLyrics(dummySong);

      expect(result.isSuccess(), isTrue);
      expect(result.getOrThrow(), 'Test synced lyrics');
      verify(() => mockDb.updateSong(any())).called(1);
    });

    test('fetchAndSaveMissingArtwork skips if artwork already exists', () async {
      final songWithArt = dummySong.copyWith(imagePath: '/local/art.png');
      final result = await repository.fetchAndSaveMissingArtwork(songWithArt);
      expect(result.isSuccess(), isTrue);
      verifyNever(() => mockAudioDb.searchAlbum(any(), any()));
    });

    test('validateAndFixID3Tags gracefully handles AudioTags native file exception during editTags', () async {
      // Mock AudioDB returning valid track and album data
      when(() => mockAudioDb.searchTrack('Test Song', 'Test Artist'))
          .thenAnswer((_) async => Success<Map<String, dynamic>, Exception>({
            'track': <dynamic>[{'strTrack': 'New Title', 'strArtist': 'New Artist', 'idAlbum': '123'}]
          }));
      
      when(() => mockAudioDb.searchAlbum('Test Album', 'New Artist'))
          .thenAnswer((_) async => Success<Map<String, dynamic>, Exception>({
            'album': <dynamic>[{'idAlbum': '123', 'strAlbumThumb': 'http://image.com'}]
          }));

      // Mock HTTP response for image download
      when(() => mockHttp.get(any())).thenAnswer((_) async => http.Response('', 404));

      // Attempt validation. Because AudioTags.write requires a physical file, it will throw in headless mode
      // and correctly hit our catch block in editTags, returning a Failure.
      final result = await repository.validateAndFixID3Tags(dummySong);

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull().toString(), contains('Failed to edit song tags'));
    });
  });
}