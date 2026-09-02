import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Adjust these imports to match your project's folder structure
import 'package:music_player_app/data/providers/sync_provider.dart'; 
import 'package:music_player_app/data/providers/scrobble_provider.dart';
import 'package:music_player_app/data/services/last_fm_service.dart';
import 'package:music_player_app/data/repositories/scrobble_repository.dart';
import 'package:music_player_app/domain/managers/sync_manager.dart';

class MockLastFmService extends Mock implements LastFmService {}
class MockScrobbleRepository extends Mock implements ScrobbleRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLastFmService mockLastFmService;
  late MockScrobbleRepository mockScrobbleRepo;

  setUp(() {
    mockLastFmService = MockLastFmService();
    mockScrobbleRepo = MockScrobbleRepository();

    // Prevent the watched authProvider from crashing when looking for session keys
    FlutterSecureStorage.setMockInitialValues({});

    // Intercept connectivity_plus platform channels so startListening() doesn't crash
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return 'wifi'; // Simulate a wifi connection
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      null,
    );
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        lastFmServiceProvider.overrideWithValue(mockLastFmService),
        scrobbleRepositoryProvider.overrideWithValue(mockScrobbleRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Sync Provider Tests', () {
    
    test('syncManagerProvider builds SyncManager with injected dependencies', () {
      final container = makeContainer();

      // Reading the provider triggers instantiation, auth listening, and startListening()
      final manager = container.read(syncManagerProvider);

      // Verify the provider successfully created the real manager without crashing
      expect(manager, isA<SyncManager>());
    });

    test('syncManagerProvider safely disposes the manager', () {
      final container = makeContainer();
      
      // Initialize the manager
      final manager = container.read(syncManagerProvider);
      expect(manager, isA<SyncManager>());

      // Dispose the container (simulating app shutdown)
      // This will trigger ref.onDispose and call manager.stopListening()
      container.dispose();
      
      // A successful completion without exceptions means the cleanup ran perfectly
    });
  });
}