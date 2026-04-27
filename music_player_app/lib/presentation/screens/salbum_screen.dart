import 'package:flutter/material.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  
  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  Widget build(BuildContext context) {
    // Mock data for the artist's songs
    final List<String> _mockSongs = ['Song 1', 'Song 2', 'Song 3', 'Song 4', 'Song 5', 'Song 6'];

    return Scaffold(
      appBar: AppBar(
        title: Text(artistName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _mockSongs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.2, 
        ),
        itemBuilder: (context, index) {
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerScreen()));
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _mockSongs[index], 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}