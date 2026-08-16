import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sqflite/sqflite.dart';

import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';

import 'package:music_player_app/presentation/screens/artists_screen.dart';
import 'package:music_player_app/presentation/screens/playlist_screen.dart';
import 'package:music_player_app/presentation/screens/search_screen.dart';
import 'package:music_player_app/presentation/screens/home_screen.dart';
import 'package:music_player_app/presentation/screens/all_songs_screen.dart';
import 'package:music_player_app/presentation/screens/settings_screen.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:music_player_app/presentation/screens/lastfm_screen.dart';

class MusicDashboard extends ConsumerStatefulWidget {
  const MusicDashboard({super.key});

  @override
  ConsumerState<MusicDashboard> createState() => _MusicDashboardState();
}

class _MusicDashboardState extends ConsumerState<MusicDashboard> {
  int _selectedIndex = 0; 

  final List<Widget> _pages = [
    const HomeDashboard(),
    const SearchScreen(),
    const ArtistsScreen(),
    const PlaylistScreen(),
    const AllSongsScreen(),
    const SettingsScreen(),
    const LastFmAuthScreen(),
  ];
  
  Offset? _panelPosition; 
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
        final audioPlayer = ref.read(audioPlayerProvider);
        if (audioPlayer.sequenceState?.currentSource != null) {
          final tag = audioPlayer.sequenceState!.currentSource!.tag as MediaItem?;
          if (tag != null) {
            try {
              activeSong = songs.firstWhere((s) => s.id.toString() == tag.id);
            } catch (_) {}
          }
        }

        if (activeSong == null && songs.isNotEmpty) {
          activeSong = songs.first;
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
    int? lastProcessedIndex;
    final audioPlayer = ref.read(audioPlayerProvider);

    _sequenceStateSubscription = audioPlayer.sequenceStateStream.listen((sequence) {
      if (sequence?.currentSource != null) {
        final tag = sequence!.currentSource!.tag as MediaItem;
        try {
          final activeSong = _allSongs.firstWhere((s) => s.id.toString() == tag.id);
          
          if (mounted) {
            setState(() => _currentActiveSong = activeSong);
          }

          if (lastProcessedIndex != null && lastProcessedIndex != sequence.currentIndex) {
            final previousSource = sequence.sequence[lastProcessedIndex!];
            final prevTag = previousSource.tag as MediaItem?;
            if (prevTag != null) {
              final prevSong = _allSongs.firstWhere((s) => s.id.toString() == prevTag.id);
              
              final databaseService = DatabaseService(databaseFactory: databaseFactory);
              final songRepo = SongRepository(database: databaseService);
              songRepo.incrementPlayCount(prevSong.id);
            }
          }
          lastProcessedIndex = sequence.currentIndex;
        } catch (_) {}
      }
    });

    _playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  Future<void> _togglePlayback() async {
    final audioPlayer = ref.read(audioPlayerProvider);
    if (audioPlayer.playing) {
      await audioPlayer.pause();
    } else {
      if (audioPlayer.sequenceState == null && _allSongs.isNotEmpty) {
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
        await audioPlayer.play();
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
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final bool isTablet = screenSize.width > 600;
    
    // --- FIX: Define strict boundaries for the mini-player ---
    // Prevent it from sliding under the transparent AppBar
    final double topBoundary = padding.top + kToolbarHeight + 10.0; 
    // Prevent it from colliding with the transparent Bottom Nav
    final double bottomNavHeight = padding.bottom + 90.0;

    // Determine shape BEFORE assigning dimensions so the bounds logic doesn't loop
    bool isHorizontal = false;
    if (_panelPosition != null) {
      // It transforms into a bar if dragged near the AppBar or near the BottomNav
      if (_panelPosition!.dy < topBoundary + 60 || _panelPosition!.dy > screenSize.height - bottomNavHeight - 180) {
        isHorizontal = true;
      }
    }

    final double currentWidth = isHorizontal ? (isTablet ? 350.0 : 260.0) : 70.0;
    final double currentHeight = isHorizontal ? 75.0 : 160.0;

    // Initial starting point (hovering right above the bottom nav area)
    _panelPosition ??= Offset(20, screenSize.height - currentHeight - bottomNavHeight - 10);

    // Explicitly clamp the gesture coordinates.
    // It can no longer physically move into the space occupied by the top or bottom icons
    _panelPosition = Offset(
      _panelPosition!.dx.clamp(0.0, screenSize.width - currentWidth),
      _panelPosition!.dy.clamp(topBoundary, screenSize.height - currentHeight - bottomNavHeight), 
    );

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.last_page, color: Colors.black),
            tooltip: 'Last.fm Integration',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LastFmAuthScreen(),
                ),
              );
            },
          ),
        ],
      ),
      
      body: Stack(
        children: [
          _pages[_selectedIndex], 
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Container(
                  width: isTablet ? 600 : double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: GNav(
                    backgroundColor: Colors.transparent,
                    color: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Colors.black87,
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
            ),
          ),

          if (_currentActiveSong != null)
            Positioned(
              left: _panelPosition!.dx,
              top: _panelPosition!.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _panelPosition = _panelPosition! + details.delta;
                  });
                },
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
                child: isHorizontal 
                    ? _buildHorizontalMiniPlayer(currentWidth, currentHeight)
                    : _buildVerticalMiniPlayer(currentWidth, currentHeight),
              ),
            ),
        ],
      ),
    );
  }

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

  Widget _buildHorizontalMiniPlayer(double width, double height) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentActiveSong!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  _currentActiveSong!.artists.isNotEmpty ? _currentActiveSong!.artists.first : 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
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