import 'package:flutter/material.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- 1. LAST PLAYED ---
          const Text('Last Played', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10), 
          Card(
            // Removed hardcoded shape/elevation/color so it inherits from AppTheme
            child: ListTile(
              // Removed Colors.deepPurple! The ListTileTheme will now make these cyan automatically
              leading: const Icon(Icons.music_note, size: 40),
              title: const Text('Bohemian Rhapsody', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Queen'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlayerScreen(),
                  ),
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_fill, size: 36),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(height: 24), 

          // --- 2. DAILY STATS ---
          const Text('Daily Stats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Passed 'context' so the helper method can read your global theme
              _buildStatCard(context, 'Time Listened', '2h 14m', Icons.timer),
              const SizedBox(width: 16), 
              _buildStatCard(context, 'Tracks', '34', Icons.bar_chart),
            ],
          ),
          const SizedBox(height: 24),

          // --- 3. MOST REPRODUCED ---
          const Text('Most Reproduced', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 140, 
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                // Swapped Container for a Card so it automatically matches your dark theme surfaces!
                return Card(
                  margin: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Removed hardcoded Colors.grey
                        const Icon(Icons.album, size: 50),
                        const SizedBox(height: 8),
                        Text('Song ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
        ],
      ),
    );
  }

  // Updated helper method to require BuildContext
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dynamically pulls the glowing Cyan accent from your AppTheme
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              // Pulls the soft grey label style directly from your AppTheme typography
              Text(title, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}