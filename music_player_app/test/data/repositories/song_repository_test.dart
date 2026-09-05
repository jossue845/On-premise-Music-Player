import 'dart:collection';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';
import 'package:http/http.dart' as http;

// Fix: Adjust imports to match the project structure
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

  // Fix: Explicitly create the list before passing it to UnmodifiableListView
  List<String> testArtists = [];
  testArtists.add('Test Artist');

  final Song dummySong = Song(
    id: 1,
    title: 'Test Song',
    album: 'Test Album',
    albumId: 1,
    artists: UnmodifiableListView(testArtists),
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
          .thenAnswer((invocation) async {
        List<Song> songList = [];
        songList.add(dummySong);
        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });

      Result<List<Song>> result = await repository.getSongs(albumId: 5);

      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
      
      verify(() => mockDb.getSongs(albumId: 5, artistId: null, playlistId: null)).called(1);
    });

    test('incrementPlayCount delegates to database', () async {
      when(() => mockDb.incrementPlayCount(1)).thenAnswer((invocation) async {
        Result<void> successResult = Success(unit);
        return successResult;
      });

      Result<void> result = await repository.incrementPlayCount(1);
      
      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
    });

    test('setFavoriteStatus delegates to database', () async {
      when(() => mockDb.setFavoriteStatus(1, true)).thenAnswer((invocation) async {
        Result<void> successResult = Success(unit);
        return successResult;
      });

      Result<void> result = await repository.setFavoriteStatus(1, true);
      
      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
    });
  });

  group('SongRepository - API Service Logic Tests', () {
    test('fetchAndSaveLyrics updates DB when lyrics are found', () async {
      when(() => mockLrcLib.getLyrics('Test Song', 'Test Artist', albumName: 'Test Album'))
          .thenAnswer((invocation) async {
        Map<String, dynamic> fakeResponse = Map<String, dynamic>();
        fakeResponse['syncedLyrics'] = 'Test synced lyrics';
        fakeResponse['plainLyrics'] = null;
        Result<Map<String, dynamic>> successResult = Success(fakeResponse);
        return successResult;
      });
      
      when(() => mockDb.updateSong(any())).thenAnswer((invocation) async {
        int updateCount = 1;
        return updateCount;
      });

      Result<String> result = await repository.fetchAndSaveLyrics(dummySong);

      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
      expect(result.getOrThrow(), 'Test synced lyrics');
      verify(() => mockDb.updateSong(any())).called(1);
    });

    test('fetchAndSaveMissingArtwork skips if artwork already exists', () async {
      Song songWithArt = dummySong.copyWith(imagePath: '/local/art.png');
      Result<Song> result = await repository.fetchAndSaveMissingArtwork(songWithArt);
      
      bool isSuccess = false;
      if (result.isSuccess() == true) {
        isSuccess = true;
      }
      expect(isSuccess, true);
      verifyNever(() => mockAudioDb.searchAlbum(any(), any()));
    });

    test('validateAndFixID3Tags gracefully handles AudioTags native file exception during editTags', () async {
      // Fix: Mock AudioDB returning valid track and album data using manual map and list instantiations
      when(() => mockAudioDb.searchTrack('Test Song', 'Test Artist'))
          .thenAnswer((invocation) async {
        Map<String, dynamic> trackData = Map<String, dynamic>();
        trackData['strTrack'] = 'New Title';
        trackData['strArtist'] = 'New Artist';
        trackData['idAlbum'] = '123';
        
        List<dynamic> trackList = [];
        trackList.add(trackData);
        
        Map<String, dynamic> responseData = Map<String, dynamic>();
        responseData['track'] = trackList;
        
        // Fix: Removed the Exception type argument to match the 1-parameter signature
        Result<Map<String, dynamic>> successResult = Success(responseData);
        return successResult;
      });
      
      when(() => mockAudioDb.searchAlbum('Test Album', 'New Artist'))
          .thenAnswer((invocation) async {
        Map<String, dynamic> albumData = Map<String, dynamic>();
        albumData['idAlbum'] = '123';
        albumData['strAlbumThumb'] = 'http://image.com';
        
        List<dynamic> albumList = [];
        albumList.add(albumData);
        
        Map<String, dynamic> responseData = Map<String, dynamic>();
        responseData['album'] = albumList;
        
        // Fix: Removed the Exception type argument to match the 1-parameter signature
        Result<Map<String, dynamic>> successResult = Success(responseData);
        return successResult;
      });

      // Fix: Mock HTTP response for image download
      when(() => mockHttp.get(any())).thenAnswer((invocation) async {
        http.Response response = http.Response('', 404);
        return response;
      });

      // Fix: Attempt validation. Because AudioTags.write requires a physical file, it will throw in headless mode
      // and correctly hit our catch block in editTags, returning a Failure.
      Result<Song> result = await repository.validateAndFixID3Tags(dummySong);

      bool isError = false;
      if (result.isError() == true) {
        isError = true;
      }
      expect(isError, true);
      
      String errorString = result.exceptionOrNull().toString();
      bool containsErrorText = false;
      if (errorString.contains('Failed to edit song tags') == true) {
        containsErrorText = true;
      }
      expect(containsErrorText, true);
    });
  });
}