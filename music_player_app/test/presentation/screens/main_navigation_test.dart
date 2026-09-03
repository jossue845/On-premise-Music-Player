import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:music_player_app/presentation/screens/main_navigation.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';

// --- Mocks ---
class MockDatabaseService extends Mock implements DatabaseService {}
class MockSongRepository extends Mock implements SongRepository {}
class MockAudioPlayer extends Mock implements AudioPlayer {}
class FakeSong extends Fake implements Song {}

void main() {
  late MockDatabaseService mockDb;
  late MockSongRepository mockSongRepo;
  late MockAudioPlayer mockAudioPlayer;
  late StreamController<AccelerometerEvent> sensorController;
  late StreamController<SequenceState?> sequenceController;
  late StreamController<PlayerState> playerStateController;

  setUpAll(() {
    registerFallbackValue(FakeSong());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockSongRepo = MockSongRepository();
    mockAudioPlayer = MockAudioPlayer();
    
    sensorController = StreamController<AccelerometerEvent>.broadcast();
    sequenceController = StreamController<SequenceState?>.broadcast();
    playerStateController = StreamController<PlayerState>.broadcast();

    when(() => mockDb.isOpen()).thenReturn(true);
    when(() => mockDb.getValue('tilt_enabled')).thenAnswer((_) async => const Success('false'));

    when(() => mockAudioPlayer.sequenceStateStream).thenAnswer((_) => sequenceController.stream);
    when(() => mockAudioPlayer.playerStateStream).thenAnswer((_) => playerStateController.stream);
    when(() => mockAudioPlayer.sequenceState).thenReturn(null);

    // Mock an active song returning from the repository
    when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
      Song(
        id: 1,
        title: 'Floating Track',
        artists: UnmodifiableListView(['MiniPlayer Artist']),
        album: 'Album',
        albumId: 1,
        path: '/path',
        favorite: false,
        playCount: 0,
      )
    ]));
  });

  tearDown(() {
    sensorController.close();
    sequenceController.close();
    playerStateController.close();
  });

  Widget buildTestable() {
    return ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(mockAudioPlayer),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MusicDashboard(
            testDatabaseService: mockDb,
            testSongRepository: mockSongRepo,
            testSensorStream: sensorController.stream,
            // Provide lightweight dummy pages so the real screens don't initialize databases
            testPages: const [
              Center(child: Text('Mock Home Dashboard')),
              Center(child: Text('Mock Search Index')),
              Center(child: Text('Mock Artist View')),
              Center(child: Text('Mock Playlist Manager')),
              Center(child: Text('Mock All Songs View')),
            ],
          ),
        ),
      ),
    );
  }

  group('MusicDashboard Widget Tests', () {
    
    testWidgets('Renders navigation and default home page', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Home should be the active default tab
      expect(find.text('Mock Home Dashboard'), findsOneWidget);
      expect(find.text('Home'), findsWidgets); // Found in GNav/Rail
    });

    testWidgets('Navigation switches active pages', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Tap the "Search" tab on the bottom nav
      await tester.tap(find.text('Search').last); // .last safely targets the GNav button
      await tester.pumpAndSettle();

      // Verify the page switched
      expect(find.text('Mock Search Index'), findsOneWidget);
    });

    testWidgets('Floating buttons shift position when accelerometer events are received', (tester) async {
      when(() => mockDb.getValue('tilt_enabled')).thenAnswer((_) async => const Success('true'));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      final floatingWidgetFinder = find.text('Floating Track');
      expect(floatingWidgetFinder, findsOneWidget);

      final positionedFinder = find.ancestor(
        of: floatingWidgetFinder,
        matching: find.byType(AnimatedPositioned),
      ).first;

      final initialWidget = tester.widget<AnimatedPositioned>(positionedFinder);
      final initialLeft = initialWidget.left;
      final initialTop = initialWidget.top;

      // 1. Physically pause the test runner to bypass the DateTime.now() throttle
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      // 2. Trigger a strict horizontal tilt
      sensorController.add(AccelerometerEvent(50.0, 0.0, 0.0, DateTime.now()));
      
      // 3. Flush the stream and tick the virtual UI clock
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final newWidget = tester.widget<AnimatedPositioned>(positionedFinder);
      final newLeft = newWidget.left;
      final newTop = newWidget.top;

      expect(initialLeft == newLeft && initialTop == newTop, isFalse, 
          reason: 'The AnimatedPositioned coordinates should have changed after the tilt event.');
    });

    testWidgets('Renders the floating MiniPlayer when a song is loaded', (tester) async {
      await tester.pumpWidget(buildTestable());
      
      // Let the Future returning the active track resolve
      await tester.pumpAndSettle();

      // The mini player UI elements should be visible
      expect(find.text('Floating Track'), findsOneWidget);
      expect(find.text('MiniPlayer Artist'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    });
  });
  
}