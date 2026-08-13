import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/services/last_fm_service.dart';
import '../../data/repositories/scrobble_repository.dart';
import '../models/scrobble/scrobble.dart';

class ScrobbleManager {
  final AudioPlayer audioPlayer;
  final LastFmService lastFmService;
  final ScrobbleRepository scrobbleRepository;
  
  // State tracking
  String? _sessionKey;
  String? _currentTrackId;
  bool _nowPlayingSent = false;
  bool _meetsScrobbleThreshold = false;
  bool _hasBeenScrobbled = false;
  int _trackStartTime = 0;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _sequenceSubscription;

  ScrobbleManager({
    required this.audioPlayer,
    required this.lastFmService,
    required this.scrobbleRepository,
  });

  /// Call this when the user logs in or out
  void updateSessionKey(String? sessionKey) {
    _sessionKey = sessionKey;
  }

  /// Starts listening to the audio player streams
  void startListening() {
    // 1. Listen for track changes
    _sequenceSubscription = audioPlayer.sequenceStateStream.listen((state) {
      if (state == null || state.currentSource == null) return;
      
      final mediaItem = state.currentSource!.tag; // Assuming JustAudioBackground MediaItem
      final trackId = mediaItem.id;

      if (_currentTrackId != trackId) {
        // Track changed: Process the previous track if it met the threshold
        _processPendingScrobble();
        
        // Reset state for the new track
        _currentTrackId = trackId;
        _nowPlayingSent = false;
        _meetsScrobbleThreshold = false;
        _hasBeenScrobbled = false;
        _trackStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        _sendNowPlaying(mediaItem);
      }
    });

    // 2. Listen to playback position to evaluate the 50% / 240s rule
    _positionSubscription = audioPlayer.positionStream.listen((position) {
      if (_meetsScrobbleThreshold || _hasBeenScrobbled) return;

      final duration = audioPlayer.duration;
      if (duration == null || duration.inSeconds == 0) return;

      final playedSeconds = position.inSeconds;
      final totalSeconds = duration.inSeconds;

      // Rule: 50% of the track OR 4 minutes (240 seconds), whichever comes first
      final targetSeconds = (totalSeconds / 2).clamp(0, 240);

      if (playedSeconds >= targetSeconds) {
        _meetsScrobbleThreshold = true;
        debugPrint('Scrobble threshold reached for $_currentTrackId');
      }
    });
  }

  void stopListening() {
    _positionSubscription?.cancel();
    _sequenceSubscription?.cancel();
  }

  Future<void> _sendNowPlaying(dynamic mediaItem) async {
    if (_sessionKey == null || _nowPlayingSent) return;

    try {
      final scrobble = Scrobble(
        artist: mediaItem.artist ?? 'Unknown Artist',
        track: mediaItem.title,
        album: mediaItem.album,
        timestamp: _trackStartTime,
      );

      await lastFmService.updateNowPlaying(scrobble, _sessionKey!);
      _nowPlayingSent = true;
    } catch (e) {
      debugPrint('Now Playing update failed: $e');
    }
  }

  Future<void> _processPendingScrobble() async {
    if (!_meetsScrobbleThreshold || _hasBeenScrobbled) return;

    // Retrieve current media info before it's gone
    final sequence = audioPlayer.sequenceState?.sequence;
    if (sequence == null || sequence.isEmpty) return;
    
    // Find the media item that matches our tracked ID
    final currentSource = sequence.firstWhere(
      (source) => source.tag.id == _currentTrackId,
      orElse: () => sequence.first,
    );
    final mediaItem = currentSource.tag;

    final scrobble = Scrobble(
      artist: mediaItem.artist ?? 'Unknown Artist',
      track: mediaItem.title,
      album: mediaItem.album,
      timestamp: _trackStartTime,
      isSynced: false,
    );

    try {
      // 1. Save to local database first
      final id = await scrobbleRepository.insertScrobble(scrobble);
      
      // 2. If we have a session key, attempt to sync immediately
      if (_sessionKey != null) {
        await lastFmService.scrobble([scrobble], _sessionKey!);
        await scrobbleRepository.markAsSynced([id]);
        debugPrint('Successfully scrobbled track to Last.fm');
      }
    } catch (e) {
      debugPrint('Scrobble sync failed, kept in local cache. Error: $e');
    } finally {
      _hasBeenScrobbled = true;
    }
  }
}