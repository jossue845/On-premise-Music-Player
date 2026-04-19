import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// Other screens in this project
import 'package:music_player_app/presentation/screens/artists_screen.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:music_player_app/presentation/screens/playlist_screen.dart';
import 'package:music_player_app/presentation/screens/search_screen.dart';
import 'package:music_player_app/presentation/screens/home_screen.dart';
import 'package:music_player_app/presentation/screens/settings_screen.dart';

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
    const PlayerScreen(),
    const SettingsScreen(),
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
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
                ),
              );
          }, 
          icon: const Icon(
            Icons.settings,
            color : Colors.black,
          )
          ),
      ),
      body: _pages[_selectedIndex], 
      
      bottomNavigationBar: Container(
        color: Colors.white,
        child : Padding (
          padding: const EdgeInsets.symmetric(horizontal : 15.0, vertical: 20),
          child: GNav(
            backgroundColor: Colors.white,
            color : Colors.grey,
            activeColor: Colors.deepPurple,
            tabBackgroundColor: Colors.deepPurple.withOpacity(0.1),
            padding: const EdgeInsets.all(16), 
            selectedIndex: _selectedIndex, 
            onTabChange: _onItemTapped, 
            tabs: const [
              GButton(
                icon: Icons.home,
                text: 'Home'
                ),
              GButton(
                icon: Icons.search,
                text: 'Search',
              ),
              GButton(
                icon: Icons.person,
                text: 'Artist',
              ),
              GButton(
                icon: Icons.queue_music,
                text: 'Playlists',
              ),
            ],
          ),
        ),

      ),
    );
  }
}