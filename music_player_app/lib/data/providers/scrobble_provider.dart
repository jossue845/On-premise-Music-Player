import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/managers/scrobble_manager.dart';
import 'auth_provider.dart';
import '../services/last_fm_service.dart';
import '../repositories/scrobble_repository.dart';
import '../services/database_service.dart';
import 'audio_player_provider.dart';
import 'package:sqflite/sqflite.dart';

final scrobbleRepositoryProvider = Provider<ScrobbleRepository>((ref) {
  final databaseService = DatabaseService(databaseFactory: databaseFactory); // Adjust based on your injection
  return ScrobbleRepository(databaseService: databaseService);
});

final scrobbleManagerProvider = Provider<ScrobbleManager>((ref) {
  final audioPlayer = ref.watch(audioPlayerProvider);
  final lastFmService = ref.watch(lastFmServiceProvider);
  final scrobbleRepository = ref.watch(scrobbleRepositoryProvider);
  
  final manager = ScrobbleManager(
    audioPlayer: audioPlayer,
    lastFmService: lastFmService,
    scrobbleRepository: scrobbleRepository,
  );

  // Watch the auth state and pass the session key to the manager
  ref.listen<AsyncValue<String?>>(authProvider, (previous, next) {
    manager.updateSessionKey(next.valueOrNull);
  }, fireImmediately: true);

  // Start listening to streams when the provider is initialized
  manager.startListening();

  // Clean up when the app is destroyed
  ref.onDispose(() {
    manager.stopListening();
  });

  return manager;
});