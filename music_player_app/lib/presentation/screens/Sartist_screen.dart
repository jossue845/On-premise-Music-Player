import 'package:flutter/material.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;
  
  const AlbumDetailScreen({super.key, required this.albumName});

  @override
  Widget build(BuildContext context) {
    // Mock data for the album tracks
    final List<Map<String, String>> _mockTracks = [
      {'title': 'Track 1', 'duration': '3:15'},
      {'title': 'Track 2', 'duration': '4:02'},
      {'title': 'Track 3', 'duration': '2:45'},
      {'title': 'Track 4', 'duration': '5:10'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(albumName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _mockTracks.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              title: Text(
                _mockTracks[index]['title']!, 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // Pulls the soft grey text style from your global theme for the duration
              trailing: Text(
                _mockTracks[index]['duration']!, 
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
              },
            ),
          );
        },
      ),
    );
  }
}