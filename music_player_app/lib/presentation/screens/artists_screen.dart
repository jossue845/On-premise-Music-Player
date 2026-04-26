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
        // GridView.builder creates the "infinite" scrolling effect efficiently
        child: GridView.builder(
          itemCount: 30, // Change this to _mockArtists.length when using real data!
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Forces exactly 2 columns
            crossAxisSpacing: 16.0, // Space between the columns
            mainAxisSpacing: 16.0, // Space between the rows
            childAspectRatio: 0.85, // Slightly taller than a perfect square to fit the text
          ),
          itemBuilder: (context, index) {
            // Loops through our mock names for demonstration
            final artistName = _mockArtists[index % _mockArtists.length];
            
            return Card(
              // Inherits the exact color and shadow from your AppTheme automatically!
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. The Artist Image ---
                  Expanded(
                    child: ClipRRect(
                      // Clips the top corners of the image to match the Card's curve
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        color: const Color(0xFF2A2A2A), // Dark placeholder background
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey, // Placeholder icon
                        ),
                        // When you have real images, replace the Icon with:
                        // Image.network('https://image-url.com/art.jpg', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  
                  // --- 2. The Artist Name ---
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
                      overflow: TextOverflow.ellipsis, // Adds "..." if the name is too long
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