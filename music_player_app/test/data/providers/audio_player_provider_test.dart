import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// Adjust this import path to point to your actual provider file
import 'package:music_player_app/data/providers/audio_player_provider.dart'; 

void main() {
  // Required to mock platform channels in a headless environment
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Intercept and swallow native platform calls made by just_audio 
    // when AudioPlayer initializes and calls setLoopMode()
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (MethodCall methodCall) async {
        return {}; // Return a dummy success response for all native calls
      },
    );
  });

  tearDown(() {
    // Clean up the mock handler after tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      null,
    );
  });

  group('AudioPlayer & Equalizer Providers', () {
    
    test('equalizerProvider creates and returns an AndroidEqualizer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final equalizer = container.read(equalizerProvider);
      
      expect(equalizer, isA<AndroidEqualizer>());
    });

    test('audioPlayerProvider initializes with loop mode all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Reading the provider triggers the AudioPlayer creation and setLoopMode call
      final player = container.read(audioPlayerProvider);

      expect(player, isA<AudioPlayer>());
      expect(player.loopMode, LoopMode.all);
    });
  });
}