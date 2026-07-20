import 'package:just_audio/just_audio.dart';

final AndroidEqualizer globalEqualizer = AndroidEqualizer();

final AudioPlayer globalAudioPlayer = AudioPlayer(
  audioPipeline: AudioPipeline(
    androidAudioEffects: [
      globalEqualizer,
    ],
  ),
);