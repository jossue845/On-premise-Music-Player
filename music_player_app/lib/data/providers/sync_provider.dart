import 'package:flutter_riverpod/flutter_riverpod.dart';

// Use absolute imports to guarantee Dart finds the files
import 'package:music_player_app/domain/managers/sync_manager.dart';
import 'package:music_player_app/data/providers/auth_provider.dart';
import 'package:music_player_app/data/providers/scrobble_provider.dart';
import 'package:music_player_app/data/services/last_fm_service.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final lastFmService = ref.watch(lastFmServiceProvider);
  final scrobbleRepository = ref.watch(scrobbleRepositoryProvider); 
  
  final manager = SyncManager(
    lastFmService: lastFmService,
    scrobbleRepository: scrobbleRepository,
  );

  ref.listen<AsyncValue<String?>>(authProvider, (previous, next) {
    manager.updateSessionKey(next.valueOrNull);
  }, fireImmediately: true);

  manager.startListening();

  ref.onDispose(() {
    manager.stopListening();
  });

  return manager;
});