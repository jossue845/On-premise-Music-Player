import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_player_app/presentation/screens/sartist_screen.dart'; 
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';

class MockSongRepository extends Mock implements SongRepository {}
class MockAudioPlayer extends Mock implements AudioPlayer {}
class FakeSong extends Fake implements Song {}
class FakeAudioSource extends Fake implements AudioSource {} 
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeRoute extends Fake implements Route<dynamic> {}

Song _buildSong(int id, String title, List<String> artists) {
  return Song(
    id: id,
    title: title,
    artists: UnmodifiableListView(artists),
    album: 'Test Album',
    albumId: 1,
    path: '/path/$id.mp3',
    favorite: false,
    playCount: 0,
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

    // Stub AudioPlayer Properties
    when(() => mockAudioPlayer.loopMode).thenReturn(LoopMode.off);
    when(() => mockAudioPlayer.shuffleModeEnabled).thenReturn(false);
    when(() => mockAudioPlayer.playing).thenReturn(false);
    when(() => mockAudioPlayer.sequenceState).thenReturn(null);
    
    // Stub Streams 
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

    // Stub Methods
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

  Widget buildTestable({required String artistName, NavigatorObserver? observer}) {
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
        home: ArtistDetailScreen(
          artistName: artistName,
          testSongRepository: mockSongRepo,
        ),
      ),
    );
  }

  group('ArtistDetailScreen Widget Tests', () {
    
    testWidgets('Shows empty state when no songs match the artist', (WidgetTester tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((invocation) async {
        List<Song> songList = [];
        List<String> artistList = [];
        artistList.add('Different Artist');
        songList.add(_buildSong(1, 'Pop Track', artistList));

        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });

      await tester.pumpWidget(buildTestable(artistName: 'Target Artist'));
      await tester.pumpAndSettle();

      expect(find.text('No songs found for Target Artist.'), findsOneWidget);
    });

    testWidgets('Filters out unrelated songs and displays matching artist', (WidgetTester tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((invocation) async {
        List<Song> songList = [];

        List<String> targetArtistList = [];
        targetArtistList.add('Target Artist');
        songList.add(_buildSong(1, 'Hit Song', targetArtistList));          
        
        List<String> otherArtistList = [];
        otherArtistList.add('Other Artist');
        songList.add(_buildSong(2, 'Wrong Song', otherArtistList)); 
        
        List<String> collabArtistList = [];
        collabArtistList.add('Another Artist');
        collabArtistList.add('Target Artist');
        songList.add(_buildSong(3, 'Collab Song', collabArtistList));          

        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });

      await tester.pumpWidget(buildTestable(artistName: 'Target Artist'));
      await tester.pumpAndSettle();

      expect(find.text('Hit Song'), findsOneWidget);
      expect(find.text('Collab Song'), findsOneWidget);
      expect(find.text('Wrong Song'), findsNothing);
    });

    testWidgets('Correctly handles Unknown Artist logic', (WidgetTester tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((invocation) async {
        List<Song> songList = [];
        
        List<String> emptyArtistList = [];
        songList.add(_buildSong(1, 'Nameless Track', emptyArtistList)); 
        
        List<String> knownArtistList = [];
        knownArtistList.add('Target Artist');
        songList.add(_buildSong(2, 'Known Track', knownArtistList)); 

        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });

      await tester.pumpWidget(buildTestable(artistName: 'Unknown Artist'));
      await tester.pumpAndSettle();

      expect(find.text('Nameless Track'), findsOneWidget);
      expect(find.text('Known Track'), findsNothing);
    });

    testWidgets('Tapping a track commands the Navigator to push a new route', (WidgetTester tester) async {
      MockNavigatorObserver mockObserver = MockNavigatorObserver();

      when(() => mockSongRepo.getSongs()).thenAnswer((invocation) async {
        List<Song> songList = [];
        List<String> artistList = [];
        artistList.add('Target Artist');
        songList.add(_buildSong(1, 'Tap Me', artistList));

        Result<List<Song>> successResult = Success(songList);
        return successResult;
      });

      await tester.pumpWidget(buildTestable(artistName: 'Target Artist', observer: mockObserver));
      await tester.pumpAndSettle();

      clearInteractions(mockObserver);

      await tester.tap(find.byType(InkWell).first);
      
      await tester.pump();

      verify(() => mockObserver.didPush(any(), any())).called(1);
    });
  });
}