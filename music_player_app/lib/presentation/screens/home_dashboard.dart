import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicDashboard(),
    ),
  );
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView allows vertical scrolling if the phone screen is short
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      // Column stacks its children vertically from top to bottom
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- 1. LAST PLAYED ---
          const Text('Last Played', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10), // Adds a little vertical breathing room
          // Card creates a raised, rounded container
          Card(
            color: Colors.deepPurple.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            // ListTile is a pre-built row perfect for text and icons
            child: ListTile(
              leading: const Icon(Icons.music_note, size: 40, color: Colors.deepPurple),
              title: const Text('Bohemian Rhapsody', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Queen'),
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
          // Row places widgets side-by-side horizontally
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // We use a custom method below to avoid writing the same card code twice
              _buildStatCard('Time Listened', '2h 14m', Icons.timer),
              const SizedBox(width: 16), 
              _buildStatCard('Tracks', '34', Icons.bar_chart),
            ],
          ),
          const SizedBox(height: 24),

          // --- 3. MOST REPRODUCED ---
          const Text('Most Reproduced', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // A horizontal ListView requires a fixed height to know how tall to be
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

  // This helper builds the tiny stat cards so our main build method stays clean
  Widget _buildStatCard(String title, String value, IconData icon) {
    // Expanded tells the card to take up equal horizontal space inside the Row
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

class MusicDashboard extends StatefulWidget {
  const MusicDashboard({super.key});

  @override
  State<MusicDashboard> createState() => _MusicDashboardState();
}

class _MusicDashboardState extends State<MusicDashboard> {
  int _selectedIndex = 0; 
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Name pending'),
      ),
      body: Center(
        child: Text('Index: $_selectedIndex', style: const TextStyle(fontSize: 24)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Artist'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'Playlists'),
        ],
      ),
    );
  }
}