import 'package:flutter/material.dart';
import 'presentation/screens/home_dashboard.dart'; // Import the new file!

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicDashboard(),
    ),
  );
}

class MusicDashboard extends StatefulWidget {
  const MusicDashboard({super.key});

  @override
  State<MusicDashboard> createState() => _MusicDashboardState();
}

class _MusicDashboardState extends State<MusicDashboard> {
  int _selectedIndex = 0; 

  final List<Widget> _pages = [
    const HomeDashboard(),
    const Center(child: Text('Search Screen', style: TextStyle(fontSize: 24))),   // Index 1
    const Center(child: Text('Artist Screen', style: TextStyle(fontSize: 24))),   // Index 2
    const Center(child: Text('Playlists Screen', style: TextStyle(fontSize: 24))),// Index 3
  ];
  
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
      body: _pages[_selectedIndex], 
      
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