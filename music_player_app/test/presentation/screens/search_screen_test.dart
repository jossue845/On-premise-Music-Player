import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_player_app/presentation/screens/search_screen.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/domain/models/artist/artist.dart';
import 'package:music_player_app/domain/models/album/album.dart';
import 'package:music_player_app/domain/models/playlist/playlist.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockSongRepository extends Mock implements SongRepository {}
class MockPlaylistRepository extends Mock implements PlaylistRepository {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class MockAudioPlayer extends Mock implements AudioPlayer {}
class FakeRoute extends Fake implements Route<dynamic> {}
class FakeSong extends Fake implements Song {}
class FakeAudioSource extends Fake implements AudioSource {}

class MockArtist extends Mock implements Artist {}
class MockAlbum extends Mock implements Album {}
class MockPlaylist extends Mock implements Playlist {}

Song _buildSong(int id, String title, String artist) {
  List<String> artistsList = [];
  artistsList.add(artist);
  
  return Song(
    id: id,
    title: title,
    artists: UnmodifiableListView(artistsList),
    album: 'Test Album',
    albumId: 1,
    path: '/path/$id.mp3',
    favorite: false,
    playCount: 0,
  );
}

void main() {
  late MockDatabaseService mockDb;
  late MockSongRepository mockSongRepo;
  late MockPlaylistRepository mockPlaylistRepo;
  late MockAudioPlayer mockAudioPlayer;

  setUpAll(() {
    registerFallbackValue(FakeRoute());
    registerFallbackValue(FakeSong());
    registerFallbackValue(FakeAudioSource());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockSongRepo = MockSongRepository();
    mockPlaylistRepo = MockPlaylistRepository();
    mockAudioPlayer = MockAudioPlayer();

    when(() => mockDb.isOpen()).thenReturn(true);

    when(() => mockAudioPlayer.loopMode).thenReturn(LoopMode.off);
    when(() => mockAudioPlayer.shuffleModeEnabled).thenReturn(false);
    when(() => mockAudioPlayer.playing).thenReturn(false);
    when(() => mockAudioPlayer.sequenceState).thenReturn(null);
    
    when(() => mockAudioPlayer.sequenceStateStream).thenAnswer((invocation) {
      return const Stream.empty();
    });
    
    when(() => mockAudioPlayer.playerStateStream).thenAnswer((invocation) {
      return const Stream.empty();
    });
    
    when(() => mockAudioPlayer.positionStream).thenAnswer((invocation) {
      return const Stream.empty();
    });
    
    when(() => mockAudioPlayer.durationStream).thenAnswer((invocation) {
      return const Stream.empty();
    });
    
    when(() => mockAudioPlayer.currentIndexStream).thenAnswer((invocation) {
      return const Stream.empty();
    });
    
    when(() => mockAudioPlayer.setAudioSource(
      any(), 
      initialIndex: any(named: 'initialIndex'), 
      initialPosition: any(named: 'initialPosition')
    )).thenAnswer((invocation) async {
      Duration zeroDuration = Duration.zero;
      return zeroDuration;
    });
    
    when(() => mockAudioPlayer.play()).thenAnswer((invocation) async {
      return;
    });
    
    when(() => mockAudioPlayer.pause()).thenAnswer((invocation) async {
      return;
    });
  });

  Widget buildTestable({NavigatorObserver? observer}) {
    List<NavigatorObserver> observersList = [];
    if (observer != null) {
      observersList.add(observer);
    }

    return ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(mockAudioPlayer),
      ],
      child: MaterialApp(
        navigatorObservers: observersList,
        home: SearchScreen(
          // Fix: Feed the repositories so they can be securely passed down
          testDatabaseService: mockDb,
          testSongRepository: mockSongRepo,
          testPlaylistRepository: mockPlaylistRepo,
        ),
      ),
    );
  }

  group('SearchScreen Widget Tests', () {
    
    testWidgets('Shows empty instructions initially', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      expect(find.text("Enter a search term to find your music"), findsOneWidget);
    });

    testWidgets('Entering a query fetches and displays matching data', (WidgetTester tester) async {
      when(() => mockDb.getSongs()).thenAnswer((invocation) async {
        List<Song> songList = [];
        songList.add(_buildSong(1, 'Magic Track', 'Cool Band'));
        songList.add(_buildSong(2, 'Other Song', 'Other Band'));
        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });
      
      when(() => mockDb.getArtists()).thenAnswer((invocation) async {
        List<Artist> emptyArtistList = [];
        Result<List<Artist>> successResult = Success(emptyArtistList);
        return successResult;
      });
      
      when(() => mockDb.getAlbums()).thenAnswer((invocation) async {
        List<Album> emptyAlbumList = [];
        Result<List<Album>> successResult = Success(emptyAlbumList);
        return successResult;
      });
      
      when(() => mockDb.getPlaylists()).thenAnswer((invocation) async {
        List<Playlist> emptyPlaylistList = [];
        Result<List<Playlist>> successResult = Success(emptyPlaylistList);
        return successResult;
      });

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'magic');
      await tester.pumpAndSettle();

      expect(find.text('Magic Track'), findsOneWidget);
      expect(find.text('Other Song'), findsNothing);
    });

    testWidgets('Clicking a song result navigates correctly', (WidgetTester tester) async {
      MockNavigatorObserver mockObserver = MockNavigatorObserver();
      
      when(() => mockDb.getSongs()).thenAnswer((invocation) async {
        List<Song> songList = [];
        songList.add(_buildSong(1, 'Target Track', 'Some Band'));
        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });
      
      when(() => mockDb.getArtists()).thenAnswer((invocation) async {
        List<Artist> emptyArtistList = [];
        Result<List<Artist>> successResult = Success(emptyArtistList);
        return successResult;
      });
      
      when(() => mockDb.getAlbums()).thenAnswer((invocation) async {
        List<Album> emptyAlbumList = [];
        Result<List<Album>> successResult = Success(emptyAlbumList);
        return successResult;
      });
      
      when(() => mockDb.getPlaylists()).thenAnswer((invocation) async {
        List<Playlist> emptyPlaylistList = [];
        Result<List<Playlist>> successResult = Success(emptyPlaylistList);
        return successResult;
      });

      await tester.pumpWidget(buildTestable(observer: mockObserver));
      await tester.pumpAndSettle();

      clearInteractions(mockObserver);

      await tester.enterText(find.byType(TextField), 'target');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Target Track'));
      await tester.pump();

      verify(() => mockObserver.didPush(any(), any())).called(1);
    });
  });
}