import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:music_player_app/utils/global_player.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  late DatabaseService _databaseService;
  late SongRepository _songRepository;
  List<Song> _allSongs = []; 
  bool _isLoading = false;

  // --- Real Audio Engine State ---
  Song? _currentActiveSong; 
  bool _isPlaying = false;
  
  // --- Timer State ---
  int _secondsListened = 0;
  Timer? _playbackTimer;

  // Stream Subscriptions
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _sequenceStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadSongs();
    _loadTotalTime(); // Fetch saved time from DB
    _setupAudioStreams();
  }

  @override
  void dispose() {
    _stopTimer();
    _playerStateSubscription?.cancel();
    _sequenceStateSubscription?.cancel();
    super.dispose();
  }

  void _initializeServices() {
    _databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: _databaseService);
  }

  Future<void> _loadTotalTime() async {
    try {
      // Ensure the database is actually open before reading
      if (!_databaseService.isOpen()) {
        await _databaseService.open();
      }
      
      final result = await _databaseService.getValue('total_time_listened');
      if (result.isSuccess()) {
        if (mounted) {
          setState(() {
            _secondsListened = int.tryParse(result.getOrThrow()) ?? 0;
          });
        }
      }
    } catch (_) {
      // Key doesn't exist yet, defaults to 0
    }
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final result = await _songRepository.getSongs();
      if (result.isSuccess()) {
        final songs = result.getOrThrow();
        
        Song? activeSong;
        
        // Check if the audio engine is ALREADY playing something right now
        if (globalAudioPlayer.sequenceState?.currentSource != null) {
          final tag = globalAudioPlayer.sequenceState!.currentSource!.tag as MediaItem?;
          if (tag != null) {
            try {
              activeSong = songs.firstWhere((s) => s.id.toString() == tag.id);
            } catch (_) {}
          }
        }
        
        // If nothing is playing, default to the first song in the library
        if (activeSong == null && songs.isNotEmpty) {
          activeSong = songs.first;
        }

        if (mounted) {
          setState(() {
            _allSongs = songs;
            _currentActiveSong = activeSong;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupAudioStreams() {
    _playerStateSubscription = globalAudioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (_isPlaying) {
            _startTimer();
          } else {
            _stopTimer();
          }
        });
      }
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

  // --- UPDATED: Save to DB every 5 seconds ---
  void _startTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsListened++);
        
        // Save to SQLite every 5 seconds to persist the data without spamming the drive
        if (_secondsListened % 5 == 0) {
          _databaseService.insertKVPair('total_time_listened', _secondsListened.toString());
        }
      }
    });
  }

  void _stopTimer() {
    _playbackTimer?.cancel();
    
    // Save exactly when paused, but ONLY if the database has finished opening
    if (_databaseService.isOpen()) {
      _databaseService.insertKVPair('total_time_listened', _secondsListened.toString());
    }
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

  String get _formattedTime {
    final hours = _secondsListened ~/ 3600;
    final minutes = (_secondsListened % 3600) ~/ 60;
    final seconds = _secondsListened % 60;

    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const Text('Last Played', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10), 
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentActiveSong != null
                  ? Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Container(
                            width: 45,
                            height: 45,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: _currentActiveSong!.imagePath != null
                                ? Image.file(File(_currentActiveSong!.imagePath!), fit: BoxFit.cover)
                                : Icon(Icons.music_note, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                          ),
                        ),
                        title: Text(
                          _currentActiveSong!.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _currentActiveSong!.artists.isNotEmpty 
                              ? _currentActiveSong!.artists.first 
                              : 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                        trailing: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, 
                            size: 36,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: _togglePlayback,
                        ),
                      ),
                    )
                  : Card(
                      child: ListTile(
                        leading: const Icon(Icons.music_note, size: 40),
                        title: const Text('No songs found'),
                        subtitle: const Text('Tap on Settings to scan for music'),
                        onTap: () {},
                      ),
                    ),
          const SizedBox(height: 24), 

          const Text('Daily Stats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(context, 'Time Listened', _formattedTime, Icons.timer),
              const SizedBox(width: 16), 
              _buildStatCard(context, 'Tracks', '${_allSongs.length}', Icons.bar_chart),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Most Reproduced', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 140, 
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allSongs.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allSongs.length.clamp(0, 5),
                        itemBuilder: (context, index) {
                          final song = _allSongs[index];
                          return Card(
                            margin: const EdgeInsets.only(right: 12),
                            clipBehavior: Clip.antiAlias, 
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(
                                      playlist: _allSongs,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 120,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4.0),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: song.imagePath != null
                                            ? Image.file(File(song.imagePath!), fit: BoxFit.cover)
                                            : Icon(Icons.music_note, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        song.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        song.artists.isNotEmpty 
                                            ? song.artists.first 
                                            : 'Unknown',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text('No songs to display. Scan for music in Settings.'),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}