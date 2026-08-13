import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
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
    _loadTotalTime(); 
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
    } catch (_) {}
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final result = await _songRepository.getSongs();
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
    final audioPlayer = ref.read(audioPlayerProvider);
    _playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (_isPlaying) {
            _startTimer();
          } else {
            _stopTimer();
          }
        });
        
        // --- NEW: Refresh UI when a song finishes ---
        if (state.processingState == ProcessingState.completed) {
          _loadSongs(); // Fetches the newly incremented play_counts from the database
        }
      }
    });
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsListened++);
        
        if (_secondsListened % 5 == 0) {
          _databaseService.insertKVPair('total_time_listened', _secondsListened.toString());
        }
      }
    });
  }

  void _stopTimer() {
    _playbackTimer?.cancel();
    if (_databaseService.isOpen()) {
      _databaseService.insertKVPair('total_time_listened', _secondsListened.toString());
    }
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

  // --- Dynamic Stat Generators ---

  String get _formattedTime {
    final hours = _secondsListened ~/ 3600;
    final minutes = (_secondsListened % 3600) ~/ 60;
    final seconds = _secondsListened % 60;

    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  String get _topArtist {
    if (_allSongs.isEmpty) return '-';
    
    final Map<String, int> artistPlays = {};
    int totalPlays = 0;

    for (var song in _allSongs) {
      String artist = 'Unknown Artist';
      if (song.artists.isNotEmpty && song.artists.first.trim().isNotEmpty) {
        artist = song.artists.first.trim();
      }
      
      // --- NEW: Disqualify untagged songs from the artist ranking ---
      if (artist != 'Unknown Artist' && artist != 'Unknown') {
        artistPlays[artist] = (artistPlays[artist] ?? 0) + song.playCount;
      }
      
      totalPlays += song.playCount;
    }
    
    var topArtist = '-';
    int maxPlays = 0;
    
    // Only search by plays if at least one song has been played
    if (totalPlays > 0 && artistPlays.isNotEmpty) {
      artistPlays.forEach((artist, plays) {
        if (plays > maxPlays) {
          maxPlays = plays;
          topArtist = artist;
        }
      });
    } else {
       // Fallback: If no songs have been played yet, show the tagged artist with the most tracks
       final Map<String, int> artistCounts = {};
       for (var song in _allSongs) {
          String artist = 'Unknown Artist';
          if (song.artists.isNotEmpty && song.artists.first.trim().isNotEmpty) {
            artist = song.artists.first.trim();
          }
          
          if (artist != 'Unknown Artist' && artist != 'Unknown') {
             artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
          }
       }
       artistCounts.forEach((artist, count) {
          if (count > maxPlays) {
             maxPlays = count;
             topArtist = artist;
          }
       });
    }
    
    return topArtist;
  }
  
  String get _topSong {
    if (_allSongs.isEmpty) return '-';
    
    final sortedSongs = List<Song>.from(_allSongs)
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
      
    if (sortedSongs.first.playCount == 0) return '-'; 
    return sortedSongs.first.title;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- LAST PLAYED ---
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

          // --- DAILY STATS ---
          const Text('Daily Stats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(context, 'Time Listened', _formattedTime, Icons.timer),
              const SizedBox(width: 16), 
              _buildStatCard(context, 'Tracks', '${_allSongs.length}', Icons.bar_chart),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(context, 'Top Artist', _topArtist, Icons.person),
              const SizedBox(width: 16), 
              _buildStatCard(context, 'Top Song', _topSong, Icons.star),
            ],
          ),
          const SizedBox(height: 32),

          // --- MOST REPRODUCED SCROLLER ---
          const Text('Most Reproduced', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final topPlayedSongs = List<Song>.from(_allSongs)
                ..sort((a, b) => b.playCount.compareTo(a.playCount));
                
              final activeTopSongs = topPlayedSongs.where((s) => s.playCount > 0).toList();

              return SizedBox(
                height: 140, 
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : activeTopSongs.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: activeTopSongs.length.clamp(0, 10),
                            itemBuilder: (context, index) {
                              final song = activeTopSongs[index];
                              return Card(
                                margin: const EdgeInsets.only(right: 12),
                                clipBehavior: Clip.antiAlias, 
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlayerScreen(
                                          playlist: activeTopSongs,
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
                            child: Text('Play some music to see your top tracks!'),
                          ),
              );
            }
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
              Text(
                value, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(title, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}