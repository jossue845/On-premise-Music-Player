import 'package:flutter/material.dart';
import 'package:music_player_app/presentation/screens/equalizer_screen.dart';

class SettingsScreen extends StatelessWidget{
  const SettingsScreen({super.key});
  
  void _scanMusic() {
    // Some functionalities...
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : const Text('Settings'),
      ),
      body: Center(
        child: Column(
          children: [
            // We might have a logo...

            // appearance? dark mode? personalizing app's colors?

            // Scan for music
            Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 25),
              child : ListTile(
                title : const Text("Look for new music"),
                onTap: _scanMusic,
              ),
            ),
            
            // Manage folders: include or exclude certain directories
            Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 25),
              child : ListTile(
                title : const Text("Songs folder"),
                onTap: () {},
              ),
            ),
            
            // Filter short tracks: to ignore audio files under a certain duration
            Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 25),
              child : ListTile(
                title : const Text("Filter tracks"),
                onTap: () {},
              ),
            ),
            
            // Equalizer
            Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 25),
              child : ListTile(
                title : const Text("Equalizer"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EqualizerScreen(),
                    ),
                  ); // <-- THIS is the closing parenthesis and semicolon you were missing!
                }, // <-- And this closes the onTap function
              ),
            ),
          ],
        ),
      ),
    );
  }
}