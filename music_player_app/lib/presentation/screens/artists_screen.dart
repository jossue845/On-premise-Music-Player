import 'package:flutter/material.dart';
import 'package:music_player_app/presentation/screens/sartist_screen.dart';
class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  final List<String> _mockArtists = const [
    'The Weeknd', 'Dua Lipa', 'Daft Punk', 'Gorillaz',
    'Arctic Monkeys', 'Tame Impala', 'Rihanna', 'Kendrick Lamar'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          itemCount: _mockArtists.length, 
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, 
            crossAxisSpacing: 16.0, 
            mainAxisSpacing: 16.0, 
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final artistName = _mockArtists[index];
            
            return Card(
              clipBehavior: Clip.antiAlias, // Keeps the tap ripple perfectly inside the card's corners
              child: InkWell(
                onTap: () {
                  // Routes directly to the Album screen as requested!
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailScreen(
                        albumName: '$artistName Tracks', // Passes the artist name to the album screen
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest, 
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.5), 
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        artistName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}