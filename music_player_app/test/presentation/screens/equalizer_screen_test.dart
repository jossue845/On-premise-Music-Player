import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:result_dart/result_dart.dart';
import 'dart:convert';

import 'package:music_player_app/presentation/screens/equalizer_screen.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockAudioPlayer extends Mock implements AudioPlayer {}
class MockAndroidEqualizer extends Mock implements AndroidEqualizer {}
class MockAndroidEqualizerParameters extends Mock implements AndroidEqualizerParameters {}
class MockAndroidEqualizerBand extends Mock implements AndroidEqualizerBand {}

void main() {
  late MockDatabaseService mockDb;
  late MockAudioPlayer mockAudioPlayer;
  late MockAndroidEqualizer mockEqualizer;
  late MockAndroidEqualizerParameters mockEqParams;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAudioPlayer = MockAudioPlayer();
    mockEqualizer = MockAndroidEqualizer();
    mockEqParams = MockAndroidEqualizerParameters();

    when(() => mockDb.isOpen()).thenReturn(true);
    when(() => mockDb.getValue('eq_presets')).thenAnswer((_) async => const Success('[]'));

    // AudioPlayer basic stubs
    when(() => mockAudioPlayer.volume).thenReturn(1.0);
    when(() => mockAudioPlayer.setVolume(any())).thenAnswer((_) async {});
    when(() => mockAudioPlayer.setPitch(any())).thenAnswer((_) async {});

    // Stub a fake equalizer band
    final fakeBand = MockAndroidEqualizerBand();
    when(() => fakeBand.gain).thenReturn(0.0);
    when(() => fakeBand.centerFrequency).thenReturn(1000.0);
    when(() => fakeBand.setGain(any())).thenAnswer((_) async {});

    // Stub Equalizer parameters
    when(() => mockEqParams.bands).thenReturn([fakeBand]);
    when(() => mockEqParams.minDecibels).thenReturn(-15.0);
    when(() => mockEqParams.maxDecibels).thenReturn(15.0);

    // Setup the Equalizer provider returns
    when(() => mockEqualizer.enabled).thenReturn(true);
    when(() => mockEqualizer.parameters).thenAnswer((_) async => mockEqParams);
  });

  Widget buildTestable() {
    return ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(mockAudioPlayer),
        equalizerProvider.overrideWithValue(mockEqualizer),
      ],
      child: MaterialApp(
        home: EqualizerScreen(
          testDatabaseService: mockDb,
        ),
      ),
    );
  }

  group('EqualizerScreen Widget Tests', () {
    
    testWidgets('Initializes correctly and loads presets from DB', (tester) async {
      final mockPreset = jsonEncode([
        {'name': 'Rock', 'preamp': 1.2, 'bands': [2.0]}
      ]);
      when(() => mockDb.getValue('eq_presets')).thenAnswer((_) async => Success(mockPreset));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Tap presets button to verify data loaded
      await tester.tap(find.text('Presets'));
      await tester.pumpAndSettle();
      
      expect(find.text('Rock'), findsOneWidget);
    });

    testWidgets('Toggles between Equalizer and Pitch menus', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Initial state should show Equalizer
      expect(find.text('PRE'), findsOneWidget); 
      expect(find.byIcon(Icons.speed), findsNothing);

      // Tap Pitch menu
      await tester.tap(find.text('Pitch'));
      await tester.pumpAndSettle();

      // Pitch controls should be visible
      expect(find.text('PRE'), findsNothing);
      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('Reset Current button resets player parameters', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Current'));
      await tester.pump();

      verify(() => mockAudioPlayer.setVolume(1.0)).called(1);
    });
  });
} 