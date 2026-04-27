import 'package:flutter/material.dart';

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  // A quick list of mock artists to test our grid layout
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
          itemCount: 30, 
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, 
            crossAxisSpacing: 16.0, 
            mainAxisSpacing: 16.0, 
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            // Loops through our mock names for demonstration
            final artistName = _mockArtists[index % _mockArtists.length];
            
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Artist Image
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        color: Colors.black, 
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey, 
                        ),
    
                      ),
                    ),
                  ),
                  
                  // Artist Name
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
            );
          },
        ),
      ),
    );
  }
}