import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Adjust these imports to match your project structure
import 'package:music_player_app/data/services/last_fm_service.dart';
import 'package:music_player_app/data/providers/auth_provider.dart';

class MockLastFmService extends Mock implements LastFmService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockLastFmService mockLastFmService;

  setUp(() {
    mockLastFmService = MockLastFmService();
    
    // --- FIX: Instruct flutter_secure_storage to use an in-memory mock map ---
    FlutterSecureStorage.setMockInitialValues({});
  });

  // Helper to create a container with our mocked Last.fm service
  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        lastFmServiceProvider.overrideWithValue(mockLastFmService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthNotifier Provider Tests', () {
    
    test('build() initializes with null when storage is empty', () async {
      final container = makeContainer();
      
      // Await the future to let the initial build() complete
      final initialKey = await container.read(authProvider.future);
      
      expect(initialKey, isNull);
    });

    test('build() loads existing session key from storage', () async {
      // Pre-populate the mock storage
      FlutterSecureStorage.setMockInitialValues({'lastfm_session_key': 'saved_test_key'});
      
      final container = makeContainer();
      final initialKey = await container.read(authProvider.future);
      
      expect(initialKey, 'saved_test_key');
    });

    test('login() success updates state and saves to secure storage', () async {
      when(() => mockLastFmService.authenticate('user123', 'pass123'))
          .thenAnswer((_) async => 'new_session_key');

      final container = makeContainer();
      
      // Trigger the login method
      await container.read(authProvider.notifier).login('user123', 'pass123');
      
      // Verify Riverpod state updated correctly
      final state = container.read(authProvider);
      expect(state.value, 'new_session_key');
      
      // Verify it was actually written to the secure storage cache
      const storage = FlutterSecureStorage();
      final storedKey = await storage.read(key: 'lastfm_session_key');
      expect(storedKey, 'new_session_key');
    });

    test('login() failure throws exception and sets error state', () async {
      when(() => mockLastFmService.authenticate('user123', 'wrong_pass'))
          .thenAnswer((_) async => null);

      final container = makeContainer();
      
      // Trigger the login method with bad credentials
      await container.read(authProvider.notifier).login('user123', 'wrong_pass');
      
      // Verify Riverpod caught the error and updated the state
      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Invalid credentials'));
    });

    test('logout() clears state and removes key from storage', () async {
      // Pre-populate the storage to simulate an already logged-in user
      FlutterSecureStorage.setMockInitialValues({'lastfm_session_key': 'saved_test_key'});
      final container = makeContainer();
      
      await container.read(authProvider.future); // Wait for init
      
      // Trigger logout
      await container.read(authProvider.notifier).logout();
      
      // Verify state is wiped
      final state = container.read(authProvider);
      expect(state.value, isNull);
      
      // Verify storage is wiped
      const storage = FlutterSecureStorage();
      final storedKey = await storage.read(key: 'lastfm_session_key');
      expect(storedKey, isNull);
    });
  });
}