import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

// Adjust these imports to match your project's folder structure
import 'package:music_player_app/data/providers/scrobble_provider.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';
import 'package:music_player_app/data/services/last_fm_service.dart';
import 'package:music_player_app/data/repositories/scrobble_repository.dart';
import 'package:music_player_app/domain/managers/scrobble_manager.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}
class MockLastFmService extends Mock implements LastFmService {}
class MockScrobbleRepository extends Mock implements ScrobbleRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioPlayer mockAudioPlayer;
  late MockLastFmService mockLastFmService;
  late MockScrobbleRepository mockScrobbleRepo;

  setUp(() {
    mockAudioPlayer = MockAudioPlayer();
    mockLastFmService = MockLastFmService();
    mockScrobbleRepo = MockScrobbleRepository();

    // Prevent the watched authProvider from crashing when looking for session keys
    FlutterSecureStorage.setMockInitialValues({});

    // Stub AudioPlayer streams that ScrobbleManager likely listens to on init
    when(() => mockAudioPlayer.playerStateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.sequenceStateStream).thenAnswer((_) => const Stream.empty());
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        // --- FIX: Override the provider to bypass the physical DatabaseService ---
        scrobbleRepositoryProvider.overrideWithValue(mockScrobbleRepo),
        audioPlayerProvider.overrideWithValue(mockAudioPlayer),
        lastFmServiceProvider.overrideWithValue(mockLastFmService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Scrobble Providers Tests', () {
    
    test('scrobbleManagerProvider builds ScrobbleManager with injected dependencies', () {
      final container = makeContainer();

      // Reading the provider triggers the instantiation, authProvider listening, and startListening()
      final manager = container.read(scrobbleManagerProvider);

      // Verify the provider successfully created the real manager without crashing
      expect(manager, isA<ScrobbleManager>());
    });

    test('scrobbleManagerProvider safely disposes the manager', () {
      final container = makeContainer();
      
      // Initialize the manager
      final manager = container.read(scrobbleManagerProvider);
      expect(manager, isA<ScrobbleManager>());

      // Dispose the container (simulating app shutdown)
      // If stopListening() had any unhandled exceptions, it would surface here.
      container.dispose();
      
      // No explicit expect needed; a successful completion means no memory leaks or crashes during ref.onDispose
    });
  });
}