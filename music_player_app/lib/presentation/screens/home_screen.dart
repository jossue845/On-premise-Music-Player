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
            color: Colors.deepPurple.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.music_note, size: 40, color: Colors.deepPurple),
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
                icon: const Icon(Icons.play_circle_fill, size: 36, color: Colors.deepPurple),
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
              _buildStatCard('Time Listened', '2h 14m', Icons.timer),
              const SizedBox(width: 16), 
              _buildStatCard('Tracks', '34', Icons.bar_chart),
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
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.album, size: 50, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Song ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          
        ],
      ),
    );
  }

  // Helper builds the tiny stat cards so our main build method stays clean
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}