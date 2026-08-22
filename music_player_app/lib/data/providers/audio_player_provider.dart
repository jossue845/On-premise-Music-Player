import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// Provides a single, global AndroidEqualizer instance
final equalizerProvider = Provider<AndroidEqualizer>((ref) {
  return AndroidEqualizer();
});

// Provides the AudioPlayer configured with the equalizer pipeline
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final equalizer = ref.watch(equalizerProvider);
  final player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [equalizer],
    ),
  );

  // --- FIX: Force the player to loop playlists infinitely by default ---
  player.setLoopMode(LoopMode.all);

  ref.onDispose(() {
    player.dispose();
  });

  return player;
});