import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/presentation/screens/equalizer_screen.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';

// --- Mocks ---
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
  late MockAndroidEqualizerBand mockBand1;
  late MockAndroidEqualizerBand mockBand2;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAudioPlayer = MockAudioPlayer();
    mockEqualizer = MockAndroidEqualizer();
    mockEqParams = MockAndroidEqualizerParameters();
    mockBand1 = MockAndroidEqualizerBand();
    mockBand2 = MockAndroidEqualizerBand();

    // 1. Stub Database Service
    when(() => mockDb.isOpen()).thenReturn(true);
    when(() => mockDb.getValue('eq_presets')).thenAnswer((_) async => const Success('[]'));

    // 2. Stub Audio Player
    when(() => mockAudioPlayer.volume).thenReturn(1.0);
    when(() => mockAudioPlayer.setVolume(any())).thenAnswer((_) async => {});
    when(() => mockAudioPlayer.setPitch(any())).thenAnswer((_) async => {});

    // 3. Stub Equalizer Parameters & Bands
    when(() => mockEqualizer.enabled).thenReturn(false);
    when(() => mockEqualizer.setEnabled(any())).thenAnswer((_) async => {});
    when(() => mockEqualizer.parameters).thenAnswer((_) async => mockEqParams);

    when(() => mockEqParams.maxDecibels).thenReturn(15.0);
    when(() => mockEqParams.minDecibels).thenReturn(-15.0);
    when(() => mockEqParams.bands).thenReturn([mockBand1, mockBand2]);

    when(() => mockBand1.gain).thenReturn(0.0);
    when(() => mockBand1.centerFrequency).thenReturn(60.0);
    when(() => mockBand1.setGain(any())).thenAnswer((_) async => {});

    when(() => mockBand2.gain).thenReturn(0.0);
    when(() => mockBand2.centerFrequency).thenReturn(230.0);
    when(() => mockBand2.setGain(any())).thenAnswer((_) async => {});
  });

  Widget buildTestable() {
    return ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(mockAudioPlayer),
        equalizerProvider.overrideWithValue(mockEqualizer),
      ],
      child: MaterialApp(
        home: EqualizerScreen(testDatabaseService: mockDb),
      ),
    );
  }

  group('EqualizerScreen Widget Tests', () {
    testWidgets('Renders EQ bands and allows volume change', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Verify EQ mode is active and bands rendered
      expect(find.text('PRE'), findsOneWidget);
      expect(find.text('60'), findsOneWidget); // formatted from 60.0
      expect(find.text('230'), findsOneWidget);

      // Verify the AudioPlayer's setVolume is called when we reset
      await tester.tap(find.text('Reset Current'));
      await tester.pumpAndSettle();
      verify(() => mockAudioPlayer.setVolume(1.0)).called(1);
    });

    testWidgets('Switches to Pitch tab and renders controls', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Tap Pitch tab
      await tester.tap(find.text('Pitch'));
      await tester.pumpAndSettle();

      // Verify Pitch mode rendered correctly
      expect(find.text('Pitch: 1.00x'), findsOneWidget);
      expect(find.text('Chipmunk'), findsOneWidget);
    });
  });
}