import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_player_app/presentation/screens/home_screen.dart';
import 'package:music_player_app/presentation/screens/listening_habits_screen.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:music_player_app/presentation/screens/sartist_screen.dart';
import 'package:music_player_app/presentation/screens/salbum_screen.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';
import 'package:music_player_app/domain/models/song/song.dart';

// 1. Setup the Mocks
class MockDatabaseService extends Mock implements DatabaseService {}
class MockSongRepository extends Mock implements SongRepository {}
class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockDatabaseService mockDb;
  late MockSongRepository mockRepo;
  late MockAudioPlayer mockAudioPlayer;

  setUp(() {
    mockDb = MockDatabaseService();
    mockRepo = MockSongRepository();
    mockAudioPlayer = MockAudioPlayer();

    // Prevent the audio player from crashing the test by returning an empty stream
    when(() => mockAudioPlayer.playerStateStream).thenAnswer((_) => const Stream.empty());

    // Provide default successful mock data for the dashboard to load
    when(() => mockDb.isOpen()).thenReturn(true);
    when(() => mockDb.getValue('total_time_listened')).thenAnswer((_) async => const Success('3600')); // 3600 seconds = 1h 0m
    when(() => mockDb.getListeningHabits()).thenAnswer((_) async => const Success({'topDay': 'Monday', 'peakTime': 'Evening'}));
    when(() => mockDb.getPlaylists()).thenAnswer((_) async => const Success([]));
    when(() => mockDb.insertKVPair(any(), any())).thenAnswer((_) async => const Success(unit)); 
    when(() => mockDb.getHeatmapData()).thenAnswer((_) async => const Success(<Map<String, dynamic>>[])); 
    
    when(() => mockRepo.getSongs()).thenAnswer((_) async => Success([
      Song(
        id: 1, 
        title: 'Test Track', 
        artists: UnmodifiableListView(['Test Artist']), 
        album: 'Test Album', 
        albumId: 1, 
        path: '/path', 
        favorite: true, 
        playCount: 5
      )
    ]));
  });

  // Helper function to build the widget inside the required Provider and Material wrapper
  Widget createHomeScreen() {
    return ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(mockAudioPlayer),
      ],
      child: MaterialApp(
        home: HomeDashboard(
          testDatabaseService: mockDb,
          testSongRepository: mockRepo,
        ),
      ),
    );
  }

  group('Home Screen Widget Tests', () {
    
    testWidgets('Renders Quick Stats and Top Tracks accurately from database', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      
      await tester.pump(); 
      await tester.pump(const Duration(seconds: 1)); 

      // Verify the Quick Stats parsed the '3600' seconds into '1h 0m'
      expect(find.text('1h 0m'), findsOneWidget);
      
      // Verify it found our 1 mock song
      expect(find.text('Total Tracks'), findsOneWidget);
      expect(find.text('1'), findsWidgets); 
      
      // Verify the song appears in the Top Tracks section
      expect(find.text('Test Track'), findsOneWidget);
      expect(find.text('Test Artist'), findsWidgets);
    });

    testWidgets('Tapping Listening Habits card navigates to Habits Screen', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); 

      // Simulate a user swiping up to scroll the view down so the card renders
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 500)); 

      // Find the specific card now that it is rendered on screen
      final habitsCard = find.text('Evening');
      expect(habitsCard, findsOneWidget);

      // Simulate a user tapping the card
      await tester.tap(habitsCard);
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); 

      // Verify that the Listening Habits Screen has been pushed onto the navigation stack
      expect(find.byType(ListeningHabitsScreen), findsOneWidget);
    });

    testWidgets('Tapping a Top Track navigates to Player Screen', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); 

      // Scroll slightly to ensure the Top Tracks section is visible
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final trackCard = find.text('Test Track');
      expect(trackCard, findsOneWidget);

      await tester.tap(trackCard);
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PlayerScreen), findsOneWidget);
    });

    testWidgets('Tapping a Top Artist navigates to Artist Detail Screen', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Scroll down to the Top Artists section
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final artistCard = find.text('Test Artist');
      // We expect 2 widgets because it appears in Top Tracks and Top Artists
      expect(artistCard, findsWidgets); 

      // Tap the one in the Top Artists row (the last one found on screen)
      await tester.tap(artistCard.last); 
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ArtistDetailScreen), findsOneWidget);
    });

    testWidgets('Tapping a Top Album navigates to Album Detail Screen', (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Scroll down to the Top Albums section
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final albumCard = find.text('Test Album');
      expect(albumCard, findsOneWidget);

      await tester.tap(albumCard);
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlbumDetailScreen), findsOneWidget);
    });

  });
}