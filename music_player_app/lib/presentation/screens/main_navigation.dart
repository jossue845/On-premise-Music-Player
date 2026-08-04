import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sqflite/sqflite.dart';

// Services & Global Audio
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/utils/global_player.dart';

// Screens
import 'package:music_player_app/presentation/screens/artists_screen.dart';
import 'package:music_player_app/presentation/screens/playlist_screen.dart';
import 'package:music_player_app/presentation/screens/search_screen.dart';
import 'package:music_player_app/presentation/screens/home_screen.dart';
import 'package:music_player_app/presentation/screens/all_songs_screen.dart';
import 'package:music_player_app/presentation/screens/settings_screen.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';

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
    const AllSongsScreen(),
    const SettingsScreen(),
  ];
  
  // --- Mini Player State ---
  Offset _panelPosition = const Offset(20, 200); // Default floating position
  Song? _currentActiveSong;
  bool _isPlaying = false;
  List<Song> _allSongs = [];
  
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _sequenceStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _setupAudioStreams();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _sequenceStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    final songRepository = SongRepository(database: databaseService);
    
    try {
      final result = await songRepository.getSongs();
      if (result.isSuccess()) {
        final songs = result.getOrThrow();
        
        Song? activeSong;
        if (globalAudioPlayer.sequenceState?.currentSource != null) {
          final tag = globalAudioPlayer.sequenceState!.currentSource!.tag as MediaItem?;
          if (tag != null) {
            try {
              activeSong = songs.firstWhere((s) => s.id.toString() == tag.id);
            } catch (_) {}
          }
        }

        if (mounted) {
          setState(() {
            _allSongs = songs;
            _currentActiveSong = activeSong;
          });
        }
      }
    } catch (_) {}
  }

  void _setupAudioStreams() {
    _playerStateSubscription = globalAudioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });

    _sequenceStateSubscription = globalAudioPlayer.sequenceStateStream.listen((sequence) {
      if (mounted && sequence?.currentSource != null) {
        final tag = sequence!.currentSource!.tag as MediaItem;
        try {
          final activeSong = _allSongs.firstWhere((s) => s.id.toString() == tag.id);
          setState(() => _currentActiveSong = activeSong);
        } catch (_) {}
      }
    });
  }

  Future<void> _togglePlayback() async {
    if (globalAudioPlayer.playing) {
      await globalAudioPlayer.pause();
    } else {
      if (globalAudioPlayer.sequenceState == null && _allSongs.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              playlist: _allSongs,
              initialIndex: 0,
            ),
          ),
        );
      } else {
        await globalAudioPlayer.play();
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions to constrain the draggable panel
    final screenSize = MediaQuery.of(context).size;
    final panelWidth = 70.0;
    final panelHeight = 160.0;

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
          icon: const Icon(Icons.settings, color: Colors.black)
        ),
      ),
      
      // --- Stack allows the vertical panel to float above the pages ---
      body: Stack(
        children: [
          // 1. The Main Content
          _pages[_selectedIndex], 
          
          // 2. The Floating Vertical Mini-Player
          if (_currentActiveSong != null)
            Positioned(
              left: _panelPosition.dx,
              top: _panelPosition.dy,
              child: GestureDetector(
                // Update position on drag
                onPanUpdate: (details) {
                  setState(() {
                    _panelPosition += details.delta;
                    
                    // Constrain to screen bounds so it doesn't get lost
                    _panelPosition = Offset(
                      _panelPosition.dx.clamp(0.0, screenSize.width - panelWidth),
                      _panelPosition.dy.clamp(0.0, screenSize.height - panelHeight - 200), // Account for bottom nav
                    );
                  });
                },
                // Open PlayerScreen on tap
                onTap: () {
                  final songIndex = _allSongs.indexOf(_currentActiveSong!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(
                        playlist: _allSongs,
                        initialIndex: songIndex != -1 ? songIndex : 0,
                      ),
                    ),
                  );
                },
                child: _buildVerticalMiniPlayer(panelWidth, panelHeight),
              ),
            ),
        ],
      ),
      
      bottomNavigationBar: Container(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        child: Padding (
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: GNav(
            backgroundColor: Colors.transparent,
            color: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
            activeColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
            tabBackgroundColor: (Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? Colors.deepPurpleAccent).withOpacity(0.1),
            padding: const EdgeInsets.all(16), 
            selectedIndex: _selectedIndex, 
            onTabChange: _onItemTapped, 
            tabs: const [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.search, text: 'Search'),
              GButton(icon: Icons.person, text: 'Artist'),
              GButton(icon: Icons.queue_music, text: 'Playlists'),
              GButton(icon: Icons.library_music_rounded, text: 'All songs'),
            ],
          ),
        ),
      ),
    );
  }

  // --- Vertical Panel UI ---
  Widget _buildVerticalMiniPlayer(double width, double height) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Album Art
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 50,
              height: 50,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              child: _currentActiveSong!.imagePath != null
                  ? Image.file(File(_currentActiveSong!.imagePath!), fit: BoxFit.cover)
                  : Icon(Icons.music_note, color: Theme.of(context).primaryColor),
            ),
          ),
          
          // Scrolling or Truncated Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              _currentActiveSong!.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          
          // Play / Pause Button
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 36,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: _togglePlayback,
          ),
        ],
      ),
    );
  }
}