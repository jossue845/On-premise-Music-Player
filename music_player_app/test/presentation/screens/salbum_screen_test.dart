import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_player_app/presentation/screens/salbum_screen.dart'; 
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';

class MockSongRepository extends Mock implements SongRepository {}
class MockAudioPlayer extends Mock implements AudioPlayer {}
class FakeSong extends Fake implements Song {}
class FakeAudioSource extends Fake implements AudioSource {} 

// Fix: Add a MockNavigatorObserver to spy on route pushes
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeRoute extends Fake implements Route<dynamic> {}

Song _buildSong(int id, String title, String album, int trackNum) {
  List<String> artistsList = [];
  artistsList.add('Test Artist');

  return Song(
    id: id,
    title: title,
    artists: UnmodifiableListView(artistsList),
    album: album,
    albumId: 1,
    path: '/path/$id.mp3',
    favorite: false,
    playCount: 0,
    trackNumber: trackNum,
  );
}

void main() {
  late MockSongRepository mockSongRepo;
  late MockAudioPlayer mockAudioPlayer;

  setUpAll(() {
    registerFallbackValue(FakeSong());
    registerFallbackValue(FakeAudioSource());
    registerFallbackValue(FakeRoute()); 
  });

  setUp(() {
    mockSongRepo = MockSongRepository();
    mockAudioPlayer = MockAudioPlayer();

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
    
    // Fix: Add the missing currentIndexStream
    when(() => mockAudioPlayer.currentIndexStream).thenAnswer((invocation) {
      return const Stream.empty();
    });

    when(() => mockAudioPlayer.setAudioSource(
      any(),
      initialIndex: any(named: 'initialIndex'),
      initialPosition: any(named: 'initialPosition'),
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

  // Fix: Accept the observer into the MaterialApp
  Widget buildTestable({required String albumName, NavigatorObserver? observer}) {
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
        home: AlbumDetailScreen(
          albumName: albumName,
          testSongRepository: mockSongRepo,
        ),
      ),
    );
  }

  group('AlbumDetailScreen Widget Tests', () {
    
    testWidgets('Shows empty state when no songs match the album', (WidgetTester tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((invocation) async {
        List<Song> songList = [];
        songList.add(_buildSong(1, 'Wrong Song', 'Other Album', 1));
        
        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });

      await tester.pumpWidget(buildTestable(albumName: 'My Album'));
      await tester.pumpAndSettle();

      expect(find.text('No tracks found for My Album.'), findsOneWidget);
    });

    testWidgets('Filters out unrelated songs and sorts by track number', (WidgetTester tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((invocation) async {
        List<Song> songList = [];
        songList.add(_buildSong(1, 'Song 2', 'Target Album', 2));
        songList.add(_buildSong(2, 'Wrong Album Song', 'Other Album', 1));
        songList.add(_buildSong(3, 'Song 1', 'Target Album', 1));
        
        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });

      await tester.pumpWidget(buildTestable(albumName: 'Target Album'));
      await tester.pumpAndSettle();

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
      expect(find.text('Wrong Album Song'), findsNothing);

      List<ListTile> listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      
      Text firstTitle = listTiles[0].title as Text;
      expect(firstTitle.data, 'Song 1');
      
      Text secondTitle = listTiles[1].title as Text;
      expect(secondTitle.data, 'Song 2');
    });

    // Fix: Verify navigation using the Observer instead of rendering the crash-prone PlayerScreen
    testWidgets('Tapping a track commands the Navigator to push a new route', (WidgetTester tester) async {
      MockNavigatorObserver mockObserver = MockNavigatorObserver();

      when(() => mockSongRepo.getSongs()).thenAnswer((invocation) async {
        List<Song> songList = [];
        songList.add(_buildSong(1, 'Tap Me', 'Target Album', 1));
        
        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });

      await tester.pumpWidget(buildTestable(albumName: 'Target Album', observer: mockObserver));
      await tester.pumpAndSettle();

      clearInteractions(mockObserver);

      await tester.tap(find.text('Tap Me'));
      
      await tester.pump();

      verify(() => mockObserver.didPush(any(), any())).called(1);
    });
  });
}