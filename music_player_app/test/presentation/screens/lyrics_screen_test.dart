import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/presentation/screens/lyrics_screen.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';

class MockSongRepository extends Mock implements SongRepository {}

// We need a fake fallback for the Song class so Mocktail can handle "any()" arguments
class FakeSong extends Fake implements Song {}

void main() {
  late MockSongRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeSong());
  });

  setUp(() {
    mockRepo = MockSongRepository();
  });

  Widget createLyricsScreen(Song song) {
    return MaterialApp(
      home: LyricsScreen(
        song: song,
        songRepository: mockRepo,
      ),
    );
  }

  group('Lyrics Screen Widget Tests', () {
    
    testWidgets('Displays local lyrics immediately without calling API', (WidgetTester tester) async {
      // 1. Arrange: Create a song that already has lyrics
      final localSong = Song(
        id: 1, 
        title: 'Local Track', 
        artists: UnmodifiableListView(['Artist']), 
        album: 'Album', 
        albumId: 1, 
        path: '/path', 
        favorite: false, 
        playCount: 0,
        lyrics: 'These are locally saved lyrics!', // Lyrics already exist
      );

      // 2. Act: Render the screen
      await tester.pumpWidget(createLyricsScreen(localSong));
      await tester.pumpAndSettle();

      // 3. Assert: Verify the local text is on the screen
      expect(find.text('These are locally saved lyrics!'), findsOneWidget);
      
      // 4. Assert: Verify the repository was NEVER called to fetch new ones
      verifyNever(() => mockRepo.fetchAndSaveLyrics(any()));
    });

    testWidgets('Fetches from API when local lyrics are missing', (WidgetTester tester) async {
      // 1. Arrange: Create a song with missing lyrics
      final emptySong = Song(
        id: 2, 
        title: 'Network Track', 
        artists: UnmodifiableListView(['Artist']), 
        album: 'Album', 
        albumId: 1, 
        path: '/path', 
        favorite: false, 
        playCount: 0,
        lyrics: null, // No lyrics yet
      );

      // Teach the mock to return a success string from the "API"
      when(() => mockRepo.fetchAndSaveLyrics(any()))
          .thenAnswer((_) async => const Success('Lyrics fetched from network!'));

      // 2. Act: Render the screen
      await tester.pumpWidget(createLyricsScreen(emptySong));
      
      // Wait for the async API call to complete
      await tester.pumpAndSettle();

      // 3. Assert: Verify the newly fetched lyrics render properly
      expect(find.text('Lyrics fetched from network!'), findsOneWidget);
      
      // 4. Assert: Verify the repository was actually commanded to fetch them
      verify(() => mockRepo.fetchAndSaveLyrics(any())).called(1);
    });

  });
}