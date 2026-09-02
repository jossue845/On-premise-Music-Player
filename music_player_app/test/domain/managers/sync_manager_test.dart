import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Adjust these imports to match your project's folder structure
import 'package:music_player_app/domain/managers/sync_manager.dart';
import 'package:music_player_app/data/services/last_fm_service.dart';
import 'package:music_player_app/data/repositories/scrobble_repository.dart';
import 'package:music_player_app/domain/models/scrobble/scrobble.dart';

class MockLastFmService extends Mock implements LastFmService {}
class MockScrobbleRepository extends Mock implements ScrobbleRepository {}
class MockConnectivity extends Mock implements Connectivity {}

// Dummy class needed for mocktail's any() matchers
class FakeScrobble extends Fake implements Scrobble {}

void main() {
  late MockLastFmService mockLastFmService;
  late MockScrobbleRepository mockScrobbleRepository;
  late MockConnectivity mockConnectivity;
  late SyncManager syncManager;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUpAll(() {
    // Register fallbacks so mocktail doesn't crash when using any() with Lists
    registerFallbackValue(<Scrobble>[]);
    registerFallbackValue(<int>[]);
    registerFallbackValue(FakeScrobble());
  });

  setUp(() {
    mockLastFmService = MockLastFmService();
    mockScrobbleRepository = MockScrobbleRepository();
    mockConnectivity = MockConnectivity();
    connectivityController = StreamController<List<ConnectivityResult>>.broadcast();

    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
    
    // Default to a valid WiFi connection for general tests
    when(() => mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);

    syncManager = SyncManager(
      lastFmService: mockLastFmService,
      scrobbleRepository: mockScrobbleRepository,
      connectivity: mockConnectivity, 
    );
  });

  tearDown(() {
    connectivityController.close();
  });

  group('SyncManager Tests', () {
    test('does not sync if session key is null', () async {
      await syncManager.forceSync();
      
      verifyNever(() => mockConnectivity.checkConnectivity());
      verifyNever(() => mockScrobbleRepository.getUnsyncedScrobbles());
    });

    test('does not sync if device is entirely offline', () async {
      // Setup mock FIRST
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      // Then trigger
      syncManager.updateSessionKey('fake_session_key');
      await pumpEventQueue();

      verifyNever(() => mockScrobbleRepository.getUnsyncedScrobbles());
    });

    test('aborts sync cleanly if there are no unsynced scrobbles', () async {
      // Setup mock FIRST
      when(() => mockScrobbleRepository.getUnsyncedScrobbles())
          .thenAnswer((_) async => []);

      // Then trigger
      syncManager.updateSessionKey('fake_session_key');
      await pumpEventQueue();

      verify(() => mockScrobbleRepository.getUnsyncedScrobbles()).called(1);
      verifyNever(() => mockLastFmService.scrobble(any(), any()));
    });

    test('batches scrobbles properly and cleans up synced records', () async {
      final fakeScrobbles = List.generate(105, (index) {
        return Scrobble(
          id: index,
          artist: 'Artist $index',
          track: 'Track $index',
          timestamp: 1000000 + index,
        );
      });

      // 1. Setup ALL mocks strictly BEFORE assigning the key
      when(() => mockScrobbleRepository.getUnsyncedScrobbles())
          .thenAnswer((_) async => fakeScrobbles);
          
      // Use async {} instead of async => {} to prevent Future<Set> TypeErrors
      when(() => mockLastFmService.scrobble(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockScrobbleRepository.markAsSynced(any()))
          .thenAnswer((_) async {});
      when(() => mockScrobbleRepository.deleteSyncedScrobbles())
          .thenAnswer((_) async {});

      // 2. Trigger the sync process via the session key update
      syncManager.updateSessionKey('fake_session_key');

      // 3. Wait for the background loop to complete
      await pumpEventQueue();

      // 4. Verify the exact batch counts
      verify(() => mockLastFmService.scrobble(any(), 'fake_session_key')).called(3);
      verify(() => mockScrobbleRepository.markAsSynced(any())).called(3);
      verify(() => mockScrobbleRepository.deleteSyncedScrobbles()).called(1);
    });

    test('startListening triggers sync automatically when network connects', () async {
      when(() => mockScrobbleRepository.getUnsyncedScrobbles())
          .thenAnswer((_) async => []);

      syncManager.startListening();
      
      syncManager.updateSessionKey('fake_session_key'); 
      await pumpEventQueue();

      // Trigger a simulated network change
      connectivityController.add([ConnectivityResult.wifi]);
      await pumpEventQueue();

      // Checked twice: once on key update, once on network event
      verify(() => mockScrobbleRepository.getUnsyncedScrobbles()).called(2);
      
      syncManager.stopListening();
    });
  });
}