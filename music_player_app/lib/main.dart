import 'package:flutter/material.dart';
import 'package:music_player_app/presentation/screens/artists_screen.dart';
import 'package:music_player_app/presentation/screens/playlist_screen.dart';
import 'package:music_player_app/presentation/screens/search_screen.dart';
import 'package:music_player_app/presentation/screens/home_screen.dart';

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
    const SearchScreen(),
    const ArtistsScreen(),
    const PlaylistScreen(),
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
        
      ),
      body: _pages[_selectedIndex], 
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Artist'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'Playlists'),
        ],
      ),
    );
  }
}