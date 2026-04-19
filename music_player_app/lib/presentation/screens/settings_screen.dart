import 'package:flutter/material.dart';

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
              padding: EdgeInsets.only(left: 25.0, top: 25),
              child : ListTile(
                title : Text("Look for new music"),
                onTap: _scanMusic,
              ),
            ),
            // Manage folders: include or exclude certain directories
            Padding(
              padding: EdgeInsets.only(left: 25.0, top: 25),
              child : ListTile(
                title : Text("Songs folder"),
                onTap: () {},
              ),
            ),
            // Filter short tracks: to ignore audio files under a certain duration
            Padding(
              padding: EdgeInsets.only(left: 25.0, top: 25),
              child : ListTile(
                title : Text("Filter tracks"),
                onTap: () {},
              ),
            ),
            // equalizer
            Padding(
              padding: EdgeInsets.only(left: 25.0, top: 25),
              child : ListTile(
                title : Text("Equalizer"),
                onTap: () {},
              ),
            ),
            // 



          ],
        ),
      ),
    );
  }
}