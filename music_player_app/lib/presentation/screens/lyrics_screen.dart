import 'package:flutter/material.dart';

class LyricsScreen extends StatelessWidget {
  final String songTitle;
  
  const LyricsScreen({super.key, required this.songTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lyrics', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  songTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      // How to obtain the lyrics pending
                      "[Verse 1]\nI'm walking in the shadow of...",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, height: 1.8), // Height 1.8 gives nice spacing between lines
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}