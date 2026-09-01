import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';
import 'package:music_player_app/domain/models/song/song.dart';

class MockSongRepository extends Mock implements SongRepository {}
class MockAudioPlayer extends Mock implements AudioPlayer {}
class FakeAudioSource extends Fake implements AudioSource {}

void main() {
  late MockSongRepository mockRepo;
  late MockAudioPlayer mockAudioPlayer;
  late List<Song> mockPlaylist;

  setUpAll(() {
    registerFallbackValue(FakeAudioSource());
  });

  setUp(() {
    mockRepo = MockSongRepository();
    mockAudioPlayer = MockAudioPlayer();

    // 1. Provide the streams and properties the PlayerScreen needs to boot up
    when(() => mockAudioPlayer.playerStateStream).thenAnswer((_) => Stream.value(PlayerState(false, ProcessingState.ready)));
    when(() => mockAudioPlayer.currentIndexStream).thenAnswer((_) => Stream.value(0));
    when(() => mockAudioPlayer.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
    when(() => mockAudioPlayer.durationStream).thenAnswer((_) => Stream.value(const Duration(minutes: 3)));
    when(() => mockAudioPlayer.loopMode).thenReturn(LoopMode.all);
    when(() => mockAudioPlayer.sequenceState).thenReturn(null);
    when(() => mockAudioPlayer.playing).thenReturn(false);
    when(() => mockAudioPlayer.currentIndex).thenReturn(0);
    when(() => mockAudioPlayer.hasNext).thenReturn(true);
    when(() => mockAudioPlayer.hasPrevious).thenReturn(false);

    // 2. Stub the async commands
    when(() => mockAudioPlayer.setAudioSource(any(), initialIndex: any(named: 'initialIndex')))
        .thenAnswer((_) async => Duration.zero);
    when(() => mockAudioPlayer.play()).thenAnswer((_) async {});
    when(() => mockAudioPlayer.pause()).thenAnswer((_) async {});
    
    // Stub the database save command for the favorite toggle
    when(() => mockRepo.setFavoriteStatus(any(), any()))
        .thenAnswer((_) async => const Success(unit));

    // 3. Create a dummy playlist
    mockPlaylist = [
      Song(
        id: 1, 
        title: 'Bohemian Rhapsody', 
        artists: UnmodifiableListView(['Queen']), 
        album: 'A Night at the Opera', 
        albumId: 1, 
        path: '/path/song.mp3', 
        favorite: false, 
        playCount: 0
      )
    ];
  });

  Widget createPlayerScreen() {
    return ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(mockAudioPlayer),
      ],
      child: MaterialApp(
        home: PlayerScreen(
          playlist: mockPlaylist,
          initialIndex: 0,
          testSongRepository: mockRepo,
        ),
      ),
    );
  }

  group('Player Screen Widget Tests', () {
    
    testWidgets('Tapping Play button triggers audio player play() command', (WidgetTester tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // 1. Verify the screen loaded our dummy song
      expect(find.text('Bohemian Rhapsody'), findsOneWidget);
      expect(find.text('Queen'), findsOneWidget);

      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      // Clear the history to ignore the startup auto-play
      clearInteractions(mockAudioPlayer);

      // 2. Simulate a user tap
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      // 3. Verify that the tap triggered exactly 1 new play() command
      verify(() => mockAudioPlayer.play()).called(1);
    });

    testWidgets('Tapping favorite button updates UI and calls repository', (WidgetTester tester) async {
      await tester.pumpWidget(createPlayerScreen());
      await tester.pumpAndSettle();

      // 1. Assert: Find the initial un-favorited icon (our dummy song has favorite: false)
      final unfavoritedIcon = find.byIcon(Icons.favorite_border);
      expect(unfavoritedIcon, findsOneWidget);

      // 2. Act: Tap the icon
      await tester.tap(unfavoritedIcon);
      await tester.pumpAndSettle();

      // 3. Assert: Verify the UI immediately updated to the filled red heart
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);

      // 4. Assert: Verify the screen commanded the repository to save song ID 1 as 'true'
      verify(() => mockRepo.setFavoriteStatus(1, true)).called(1);
    });

  });
}