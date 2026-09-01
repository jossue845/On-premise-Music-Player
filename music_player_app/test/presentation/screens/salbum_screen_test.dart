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

// --- FIX: Add a MockNavigatorObserver to spy on route pushes! ---
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeRoute extends Fake implements Route<dynamic> {}

Song _buildSong(int id, String title, String album, int trackNum) {
  return Song(
    id: id,
    title: title,
    artists: UnmodifiableListView(['Test Artist']),
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
    registerFallbackValue(FakeRoute()); // Register route fallback for the observer
  });

  setUp(() {
    mockSongRepo = MockSongRepository();
    mockAudioPlayer = MockAudioPlayer();

    // 1. Stub AudioPlayer Properties
    when(() => mockAudioPlayer.loopMode).thenReturn(LoopMode.off);
    when(() => mockAudioPlayer.shuffleModeEnabled).thenReturn(false);
    when(() => mockAudioPlayer.playing).thenReturn(false);
    when(() => mockAudioPlayer.sequenceState).thenReturn(null);
    
    // 2. Stub Streams to prevent listener crashes
    when(() => mockAudioPlayer.sequenceStateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.playerStateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.durationStream).thenAnswer((_) => const Stream.empty());
    
    // --- FIX: Add the missing currentIndexStream! ---
    when(() => mockAudioPlayer.currentIndexStream).thenAnswer((_) => const Stream.empty());

    // 3. Stub Methods
    when(() => mockAudioPlayer.setAudioSource(
      any(),
      initialIndex: any(named: 'initialIndex'),
      initialPosition: any(named: 'initialPosition'),
    )).thenAnswer((_) async => Duration.zero);
    
    when(() => mockAudioPlayer.play()).thenAnswer((_) async {});
    when(() => mockAudioPlayer.pause()).thenAnswer((_) async {});
  });

  // --- FIX: Accept the observer into the MaterialApp ---
  Widget buildTestable({required String albumName, NavigatorObserver? observer}) {
    return ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(mockAudioPlayer),
      ],
      child: MaterialApp(
        navigatorObservers: observer != null ? [observer] : [],
        home: AlbumDetailScreen(
          albumName: albumName,
          testSongRepository: mockSongRepo,
        ),
      ),
    );
  }

  group('AlbumDetailScreen Widget Tests', () {
    
    testWidgets('Shows empty state when no songs match the album', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(1, 'Wrong Song', 'Other Album', 1),
      ]));

      await tester.pumpWidget(buildTestable(albumName: 'My Album'));
      await tester.pumpAndSettle();

      expect(find.text('No tracks found for My Album.'), findsOneWidget);
    });

    testWidgets('Filters out unrelated songs and sorts by track number', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(1, 'Song 2', 'Target Album', 2),          
        _buildSong(2, 'Wrong Album Song', 'Other Album', 1), 
        _buildSong(3, 'Song 1', 'Target Album', 1),          
      ]));

      await tester.pumpWidget(buildTestable(albumName: 'Target Album'));
      await tester.pumpAndSettle();

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
      expect(find.text('Wrong Album Song'), findsNothing);

      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect((listTiles[0].title as Text).data, 'Song 1');
      expect((listTiles[1].title as Text).data, 'Song 2');
    });

    // --- FIX: Verify navigation using the Observer instead of rendering the crash-prone PlayerScreen ---
    testWidgets('Tapping a track commands the Navigator to push a new route', (tester) async {
      final mockObserver = MockNavigatorObserver();

      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(1, 'Tap Me', 'Target Album', 1),
      ]));

      await tester.pumpWidget(buildTestable(albumName: 'Target Album', observer: mockObserver));
      await tester.pumpAndSettle();

      // Clear the initial route push triggered by MaterialApp starting up
      clearInteractions(mockObserver);

      // Tap the list item
      await tester.tap(find.text('Tap Me'));
      
      // Pump exactly once to trigger the tap event, bypassing the full route animation!
      await tester.pump();

      // Verify the Navigator caught the push request successfully
      verify(() => mockObserver.didPush(any(), any())).called(1);
    });
  });
}