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
    when(() => mockAudioPlayer.sequenceStateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.playerStateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.durationStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.currentIndexStream).thenAnswer((_) => const Stream.empty());

    // Stub Methods
    when(() => mockAudioPlayer.setAudioSource(
      any(),
      initialIndex: any(named: 'initialIndex'),
      initialPosition: any(named: 'initialPosition'),
    )).thenAnswer((_) async => Duration.zero);
    
    when(() => mockAudioPlayer.play()).thenAnswer((_) async {});
    when(() => mockAudioPlayer.pause()).thenAnswer((_) async {});
  });

  Widget buildTestable({required String artistName, NavigatorObserver? observer}) {
    return ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(mockAudioPlayer),
      ],
      child: MaterialApp(
        navigatorObservers: observer != null ? [observer] : [],
        home: ArtistDetailScreen(
          artistName: artistName,
          testSongRepository: mockSongRepo,
        ),
      ),
    );
  }

  group('ArtistDetailScreen Widget Tests', () {
    
    testWidgets('Shows empty state when no songs match the artist', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(1, 'Pop Track', ['Different Artist']),
      ]));

      await tester.pumpWidget(buildTestable(artistName: 'Target Artist'));
      await tester.pumpAndSettle();

      expect(find.text('No songs found for Target Artist.'), findsOneWidget);
    });

    testWidgets('Filters out unrelated songs and displays matching artist', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(1, 'Hit Song', ['Target Artist']),          
        _buildSong(2, 'Wrong Song', ['Other Artist']), 
        _buildSong(3, 'Collab Song', ['Another Artist', 'Target Artist']),          
      ]));

      await tester.pumpWidget(buildTestable(artistName: 'Target Artist'));
      await tester.pumpAndSettle();

      expect(find.text('Hit Song'), findsOneWidget);
      expect(find.text('Collab Song'), findsOneWidget);
      expect(find.text('Wrong Song'), findsNothing);
    });

    testWidgets('Correctly handles Unknown Artist logic', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(1, 'Nameless Track', []), // Empty artists list         
        _buildSong(2, 'Known Track', ['Target Artist']), 
      ]));

      await tester.pumpWidget(buildTestable(artistName: 'Unknown Artist'));
      await tester.pumpAndSettle();

      expect(find.text('Nameless Track'), findsOneWidget);
      expect(find.text('Known Track'), findsNothing);
    });

    testWidgets('Tapping a track commands the Navigator to push a new route', (tester) async {
      final mockObserver = MockNavigatorObserver();

      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(1, 'Tap Me', ['Target Artist']),
      ]));

      await tester.pumpWidget(buildTestable(artistName: 'Target Artist', observer: mockObserver));
      await tester.pumpAndSettle();

      clearInteractions(mockObserver);

      // Target the InkWell directly to ensure the tap registers on the grid item
      await tester.tap(find.byType(InkWell).first);
      
      await tester.pump();

      verify(() => mockObserver.didPush(any(), any())).called(1);
    });
  });
}