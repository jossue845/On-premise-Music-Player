import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_player_app/presentation/screens/main_navigation.dart';
import 'package:music_player_app/presentation/components/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_player_app/data/providers/sync_provider.dart';
import 'package:music_player_app/data/providers/scrobble_provider.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.app.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FLUTTER ERROR: ${details.exception}');
      debugPrint('STACK: ${details.stack}');
    };

    // Also catches errors the framework itself reports via the platform channel
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PLATFORM DISPATCHER ERROR: $error');
      debugPrint('STACK: $stack');
      return true;
    };
 
    // Wrap the root widget in ProviderScope to enable Riverpod state management
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('ZONE UNCAUGHT ERROR: $error');
    debugPrint('STACK: $stack');
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wake up the scrobble manager on boot
    ref.read(scrobbleManagerProvider);
    ref.read(syncManagerProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MusicDashboard(), 
    );
  }
}