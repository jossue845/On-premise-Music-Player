import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/services/last_fm_service.dart';
import '../../data/repositories/scrobble_repository.dart';
import '../models/scrobble/scrobble.dart'; 

class SyncManager {
  final LastFmService lastFmService;
  final ScrobbleRepository scrobbleRepository;
  final Connectivity _connectivity; 
  
  String? _sessionKey;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncManager({
    required this.lastFmService,
    required this.scrobbleRepository,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  void updateSessionKey(String? sessionKey) {
    _sessionKey = sessionKey;
    if (_sessionKey != null) {
      forceSync();
    }
  }

  void startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
         forceSync();
      }
    });
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  Future<void> forceSync() async {
    // Prevent overlapping sync processes or syncing without authentication
    if (_sessionKey == null || _isSyncing) return;

    _isSyncing = true; // 1. Lock immediately before the async gap!

    try {
      // Double-check the current connection status before starting
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        _isSyncing = false; // 2. Unlock safely if we abort early
        return;
      }

      // 1. Fetch all unsynced scrobbles from the local SQLite cache
      final unsyncedScrobbles = await scrobbleRepository.getUnsyncedScrobbles();
      if (unsyncedScrobbles.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('Found ${unsyncedScrobbles.length} offline scrobbles. Starting sync...');

      // 2. Split into batches of 50 (Last.fm API maximum limit)
      const batchSize = 50;
      for (var i = 0; i < unsyncedScrobbles.length; i += batchSize) {
        final end = (i + batchSize < unsyncedScrobbles.length) ? i + batchSize : unsyncedScrobbles.length;
        final batch = unsyncedScrobbles.sublist(i, end);

        // 3. Upload the batch
        await lastFmService.scrobble(batch, _sessionKey!);

        // 4. Mark the specific batch as synced locally
        final ids = batch.map((s) => s.id!).toList();
        await scrobbleRepository.markAsSynced(ids);
      }
      
      debugPrint('Offline sync complete!');

      // 5. Clean up old synced records to prevent the database from growing indefinitely
      await scrobbleRepository.deleteSyncedScrobbles();
      
    } catch (e) {
      debugPrint('Sync failed. Will retry on next connection event: $e');
    } finally {
      _isSyncing = false;
    }
  }
}