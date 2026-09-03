import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

class MusicDashboard extends ConsumerStatefulWidget {
  final DatabaseService? testDatabaseService;
  final SongRepository? testSongRepository;
  final Stream<AccelerometerEvent>? testSensorStream;
  final List<Widget>? testPages;

  const MusicDashboard({
    super.key,
    this.testDatabaseService,
    this.testSongRepository,
    this.testSensorStream,
    this.testPages,
  });

  @override
  ConsumerState<MusicDashboard> createState() => _MusicDashboardState();
}

class _MusicDashboardState extends ConsumerState<MusicDashboard> {
  int _selectedIndex = 0; 
  late List<Widget> _pages;
  
  Offset? _panelPosition; 
  Song? _currentActiveSong;
  bool _isPlaying = false;
  List<Song> _allSongs = [];
  
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _sequenceStateSubscription;
  StreamSubscription? _currentIndexSubscription; // Fix: adedd stream variable to catch track jumps
  
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  bool _tiltEnabled = false;
  bool _isDragging = false; 
  bool _isManualOverride = false; 
  String _ignoredAxis = 'none'; 
  
  DateTime _lastTiltUpdate = DateTime.now();
  String _currentTilt = 'top'; 

  bool _isSidePanelOpen = false;

  @override
  void initState() {
    super.initState();
    _pages = widget.testPages ?? [
      const HomeDashboard(),
      const SearchScreen(),
      const ArtistsScreen(),
      const PlaylistScreen(),
      const AllSongsScreen(),
      const SettingsScreen(),
    ];

    _loadSongs();
    _setupAudioStreams();
    _loadTiltSetting();
    _setupSensors();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _sequenceStateSubscription?.cancel();
    _currentIndexSubscription?.cancel(); // Fix: canceled the indx subcripcion to avoid leaks
    _accelSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTiltSetting() async {
    final db = widget.testDatabaseService ?? DatabaseService(databaseFactory: databaseFactory);
    if (!db.isOpen()) await db.open();
    final res = await db.getValue('tilt_enabled');
    if (res.isSuccess() && mounted) {
      setState(() => _tiltEnabled = res.getOrThrow() == 'true');
    }
  }

  void _setupSensors() {
    final sensorStream = widget.testSensorStream ?? accelerometerEventStream();
    
    _accelSubscription = sensorStream.listen((AccelerometerEvent event) {
      if (!mounted) return; 
      if (!_tiltEnabled || _isDragging || _currentActiveSong == null) return;

      if (DateTime.now().difference(_lastTiltUpdate).inMilliseconds < 150) return;

      final screenSize = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      
      final bool isTablet = screenSize.shortestSide >= 600;
      final double scale = isTablet ? 1.5 : 1.0;
      final double railWidth = isTablet ? 72.0 : 0.0;
      
      final double panelWidth = (isTablet && _isSidePanelOpen) ? 340.0 : 0.0;
      final double effectiveWidth = screenSize.width - railWidth - panelWidth;
      
      final double topBoundary = padding.top + 5.0; 
      final double bottomNavHeight = isTablet ? padding.bottom + 10.0 : padding.bottom + 90.0;

      final double hWidth = 260.0 * scale;
      final double hHeight = 75.0 * scale;
      final double vWidth = 70.0 * scale;
      final double vHeight = 160.0 * scale;

      String newTilt = 'none';
      final double activeThreshold = _isManualOverride ? 8.5 : 6.0; 

      double logicalX = event.x;
      double logicalY = event.y;

      if (isLandscape) {
        logicalX = -event.y;
        logicalY = event.x;
      }

      if (logicalX.abs() > logicalY.abs()) {
        if (logicalX > activeThreshold) newTilt = 'left';
        else if (logicalX < -activeThreshold) newTilt = 'right';
      } else {
        if (logicalY > activeThreshold) newTilt = 'bottom';
        else if (logicalY < -activeThreshold) newTilt = 'top';
      }

      if (_isManualOverride && newTilt == _ignoredAxis) return; 

      if (newTilt != 'none' && newTilt != _currentTilt) {
        Offset? newPos;
        if (newTilt == 'left') {
          newPos = Offset(0, (screenSize.height - vHeight) / 2);
        } else if (newTilt == 'right') {
          newPos = Offset(effectiveWidth - vWidth, (screenSize.height - vHeight) / 2);
        } else if (newTilt == 'bottom') {
          newPos = Offset((effectiveWidth - hWidth) / 2, screenSize.height - hHeight - bottomNavHeight - 10);
        } else if (newTilt == 'top') {
          newPos = Offset((effectiveWidth - hWidth) / 2, topBoundary + 8.0);
        }

        if (newPos != null) {
          setState(() {
            _isManualOverride = false; 
            _ignoredAxis = 'none'; 
            _currentTilt = newTilt;
            _panelPosition = newPos;
            _lastTiltUpdate = DateTime.now();
          });
        }
      }
    });
  }

  Future<void> _loadSongs() async {
    final databaseService = widget.testDatabaseService ?? DatabaseService(databaseFactory: databaseFactory);
    final songRepository = widget.testSongRepository ?? SongRepository(database: databaseService);
    
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
    final audioPlayer = ref.read(audioPlayerProvider);

    // Fix: helpre function to snyc the UI properly when selecting a new track
    void updateActiveSong() {
      if (audioPlayer.sequenceState?.currentSource != null) {
        final tag = audioPlayer.sequenceState!.currentSource!.tag as MediaItem;
        try {
          final activeSong = _allSongs.firstWhere((s) => s.id.toString() == tag.id);
          if (mounted && _currentActiveSong?.id != activeSong.id) {
            setState(() => _currentActiveSong = activeSong);
          }
        } catch (_) {}
      }
    }

    _sequenceStateSubscription = audioPlayer.sequenceStateStream.listen((_) {
      updateActiveSong();
    });

    // Fix: lstens to index changes to update the panle immediatly
    _currentIndexSubscription = audioPlayer.currentIndexStream.listen((_) {
      updateActiveSong();
    });

    _playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          if (!_isPlaying && state.playing) {
            _isSidePanelOpen = true; 
          }
          _isPlaying = state.playing;
        });
      }
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
              playlist: List<Song>.from(_allSongs),
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
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    
    final bool isTablet = size.shortestSide >= 600;
    final bool showRail = isTablet;

    final bool showSidePanel = isTablet && _isSidePanelOpen && _currentActiveSong != null;
    final bool showMiniPlayer = _currentActiveSong != null && (!isTablet || !_isSidePanelOpen);

    final double scale = isTablet ? 1.5 : 1.0;
    
    double stackWidth = size.width;
    if (showRail) stackWidth -= 72.0;
    if (showSidePanel) stackWidth -= 340.0;
    
    final double topBoundary = padding.top + 5.0; 
    final double bottomNavHeight = showRail ? padding.bottom + 10.0 : padding.bottom + 90.0;

    bool isHorizontal = true; 
    if (_panelPosition != null) {
      if (_panelPosition!.dy < topBoundary + 60 || _panelPosition!.dy > size.height - bottomNavHeight - 180 * scale) {
        isHorizontal = true;
      } else {
        isHorizontal = false;
      }
    }

    final double currentWidth = isHorizontal ? 260.0 * scale : 70.0 * scale;
    final double currentHeight = isHorizontal ? 75.0 * scale : 160.0 * scale;

    _panelPosition ??= Offset((stackWidth - currentWidth) / 2 + 15, topBoundary + 8.0);

    _panelPosition = Offset(
      _panelPosition!.dx.clamp(0.0, (stackWidth - currentWidth) > 0 ? stackWidth - currentWidth : 0.0),
      _panelPosition!.dy.clamp(topBoundary, size.height - currentHeight - bottomNavHeight), 
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
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ).then((_) {
              _loadTiltSetting();
              _loadSongs(); 
            }); 
          },  
          icon: const Icon(Icons.settings) 
        ),
      ),
      body: Row(
        children: [
          if (showRail)
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    selectedIconTheme: IconThemeData(color: Theme.of(context).primaryColor),
                    unselectedIconTheme: const IconThemeData(color: Colors.white70),
                    selectedLabelTextStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
                    unselectedLabelTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
                      NavigationRailDestination(icon: Icon(Icons.search), label: Text('Search')),
                      NavigationRailDestination(icon: Icon(Icons.person), label: Text('Artist')),
                      NavigationRailDestination(icon: Icon(Icons.queue_music), label: Text('Playlists')),
                      NavigationRailDestination(icon: Icon(Icons.library_music_rounded), label: Text('Songs')),
                    ],
                  ),
                ),
              ),
            ),
            
          Expanded(
            child: Stack(
              children: [
                _pages[_selectedIndex], 
                
                if (!showRail)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        child: Container(
                          width: double.infinity,
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
                            color: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Colors.white70,
                            activeColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
                            tabBackgroundColor: (Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? Colors.cyanAccent).withOpacity(0.1),
                            iconSize: 20, 
                            textStyle: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, 
                              color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
                            ),
                            gap: 4, 
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10), 
                            selectedIndex: _selectedIndex, 
                            onTabChange: _onItemTapped, 
                            tabs: const [
                              GButton(icon: Icons.home, text: 'Home'),
                              GButton(icon: Icons.search, text: 'Search'),
                              GButton(icon: Icons.person, text: 'Artist'),
                              GButton(icon: Icons.queue_music, text: 'Playlists'),
                              GButton(icon: Icons.library_music_rounded, text: 'Songs'), 
                            ],
                          )
                        ),
                      ),
                    ),
                  ),

                if (showMiniPlayer)
                  AnimatedPositioned(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    left: _panelPosition!.dx,
                    top: _panelPosition!.dy,
                    child: GestureDetector(
                      onPanStart: (_) => setState(() => _isDragging = true),
                      onPanEnd: (_) {
                        setState(() {
                          _isDragging = false;
                          _isManualOverride = true; 
                          _ignoredAxis = _currentTilt; 
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _panelPosition = _panelPosition! + details.delta;
                        });
                      },
                      onTap: () {
                        if (isTablet) {
                          setState(() => _isSidePanelOpen = true);
                        } else {
                          final songIndex = _allSongs.indexOf(_currentActiveSong!);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(
                                playlist: List<Song>.from(_allSongs),
                                initialIndex: songIndex != -1 ? songIndex : 0,
                              ),
                            ),
                          );
                        }
                      },
                      child: isHorizontal 
                          ? _buildHorizontalMiniPlayer(currentWidth, currentHeight, scale)
                          : _buildVerticalMiniPlayer(currentWidth, currentHeight, scale),
                    ),
                  ),
              ],
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: showSidePanel ? 340.0 : 0.0,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 340.0,
                maxWidth: 340.0,
                child: _currentActiveSong != null 
                    ? PlayerScreen(
                        playlist: List<Song>.from(_allSongs),
                        initialIndex: _allSongs.indexOf(_currentActiveSong!) != -1 
                            ? _allSongs.indexOf(_currentActiveSong!) 
                            : 0,
                        testSongRepository: widget.testSongRepository,
                        isSidePanel: true,
                        onClose: () => setState(() => _isSidePanelOpen = false),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalMiniPlayer(double width, double height, double scale) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(35 * scale),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25 * scale),
            child: Container(
              width: 50 * scale,
              height: 50 * scale,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              child: _currentActiveSong!.imagePath != null
                  ? Image.file(File(_currentActiveSong!.imagePath!), fit: BoxFit.cover)
                  : Icon(Icons.music_note, color: Theme.of(context).primaryColor, size: 24 * scale),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              _currentActiveSong!.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10 * scale),
            ),
          ),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 36 * scale,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: _togglePlayback,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalMiniPlayer(double width, double height, double scale) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: 12.0 * scale),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(35 * scale),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25 * scale),
            child: Container(
              width: 50 * scale,
              height: 50 * scale,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              child: _currentActiveSong!.imagePath != null
                  ? Image.file(File(_currentActiveSong!.imagePath!), fit: BoxFit.cover)
                  : Icon(Icons.music_note, color: Theme.of(context).primaryColor, size: 24 * scale),
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentActiveSong!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 * scale),
                ),
                Text(
                  _currentActiveSong!.artists.isNotEmpty ? _currentActiveSong!.artists.first : 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11 * scale, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 36 * scale,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: _togglePlayback,
          ),
        ],
      ),
    );
  }
}