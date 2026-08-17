import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sqflite/sqflite.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_player_app/data/providers/audio_player_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/components/player_settings.dart';
import 'package:music_player_app/presentation/screens/edit_song_screen.dart';
import 'package:music_player_app/presentation/screens/lyrics_screen.dart';
import 'package:music_player_app/presentation/screens/equalizer_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final List<Song> playlist;
  final int initialIndex;

  const PlayerScreen({
    super.key, 
    required this.playlist, 
    required this.initialIndex,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late SongRepository _songRepository;
  late List<Song> _localPlaylist;
  late AudioPlayer _audioPlayer;
  
  // --- ADDED: PageController for swipe animations ---
  late PageController _pageController;
  
  bool _isPlaying = false;
  double _currentPosition = 0.0;
  double _totalDuration = 1.0; 
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _audioPlayer = ref.read(audioPlayerProvider);
    _currentIndex = widget.initialIndex;
    _localPlaylist = List.from(widget.playlist);
    
    // Initialize the controller at the starting song's index
    _pageController = PageController(initialPage: widget.initialIndex);
    
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);
    
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (_localPlaylist.isEmpty) return;
    _setupStreams();
    
    final targetSong = _localPlaylist[widget.initialIndex];
    final currentTag = _audioPlayer.sequenceState?.currentSource?.tag as MediaItem?;
    final isAlreadyPlaying = currentTag?.id == targetSong.id.toString();

    if (isAlreadyPlaying) {
      return; 
    }

    final currentSequence = _audioPlayer.sequenceState?.sequence;
    bool isSamePlaylist = false;
    
    if (currentSequence != null && currentSequence.length == _localPlaylist.length) {
      isSamePlaylist = true;
      for (int i = 0; i < currentSequence.length; i++) {
         final tag = currentSequence[i].tag as MediaItem?;
         if (tag?.id != _localPlaylist[i].id.toString()) {
           isSamePlaylist = false;
           break;
         }
      }
    }

    if (isSamePlaylist) {
       try {
          await _audioPlayer.seek(Duration.zero, index: widget.initialIndex);
          await _audioPlayer.play();
       } catch (e) {
          debugPrint("PLAYER SEEK ERROR: $e");
       }
       return;
    }

    try {
      final audioSources = _localPlaylist.map((song) {
        return AudioSource.uri(
          Uri.file(song.path),
          tag: MediaItem(
            id: song.id.toString(),
            title: song.title,
            artist: song.artists.isNotEmpty ? song.artists.first : 'Unknown Artist',
            album: song.album,
            artUri: song.imagePath != null ? Uri.file(song.imagePath!) : null,
          ),
        );
      }).toList();
      final playlistSource = ConcatenatingAudioSource(children: audioSources);

      await _audioPlayer.setAudioSource(playlistSource, initialIndex: widget.initialIndex);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("PLAYER ERROR: $e");
    }
  }

  void _setupStreams() {
    _audioPlayer.currentIndexStream.listen((index) {
      if (mounted && index != null && index < _localPlaylist.length) {
        final tag = _audioPlayer.sequenceState?.sequence[index].tag as MediaItem?;
        if (tag?.id == _localPlaylist[index].id.toString()) {
          setState(() {
            _currentIndex = index;
          });
          
          // --- FIX: Sync the PageView animation if the song changes automatically or via skip buttons ---
          if (_pageController.hasClients && _pageController.page?.round() != index) {
            _pageController.animateToPage(
              index, 
              duration: const Duration(milliseconds: 300), 
              curve: Curves.easeOutCubic,
            );
          }
        }
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) setState(() => _currentPosition = position.inMilliseconds.toDouble());
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) setState(() => _totalDuration = duration.inMilliseconds.toDouble());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _backScreen(BuildContext context) => Navigator.pop(context);

  void _togglePlayPause() async {
    _audioPlayer.playing ? await _audioPlayer.pause() : await _audioPlayer.play();
  }

  void _skipNext() async {
    if (_audioPlayer.hasNext) await _audioPlayer.seekToNext();
  }

  void _skipPrevious() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    } else {
      await _audioPlayer.seek(Duration.zero); 
    }
  }

  void _toggleShuffle() async {
    setState(() => _isShuffle = !_isShuffle);
    await _audioPlayer.setShuffleModeEnabled(_isShuffle);
  }

  void _toggleRepeat() async {
    LoopMode nextMode;
    switch (_loopMode) {
      case LoopMode.off: nextMode = LoopMode.all; break;
      case LoopMode.all: nextMode = LoopMode.one; break;
      case LoopMode.one: nextMode = LoopMode.off; break;
    }
    setState(() => _loopMode = nextMode);
    await _audioPlayer.setLoopMode(nextMode);
  }

  void _toggleFavorite() async {
    final currentSong = _localPlaylist[_currentIndex];
    final newFavoriteStatus = !currentSong.favorite;

    setState(() {
      _localPlaylist[_currentIndex] = currentSong.copyWith(favorite: newFavoriteStatus);
    });

    try {
      await _songRepository.setFavoriteStatus(currentSong.id, newFavoriteStatus);
    } catch (e) {
      debugPrint("Failed to save favorite status: $e");
    }
  }

  String _formatDuration(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _localPlaylist.length) return const Scaffold();

    final currentSong = _localPlaylist[_currentIndex];
    final String songTitle = currentSong.title;
    final String artistName = currentSong.artists.isNotEmpty ? currentSong.artists.first : 'Unknown Artist';
    final String albumName = currentSong.album ?? 'Unknown Album';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _backScreen(context), 
                    icon: const Icon(Icons.arrow_back)
                  ),
                  
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (String choice) async {
                      if (choice == 'edit') {
                        final didUpdate = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditSongScreen(song: currentSong)
                          ),
                        );

                        if (didUpdate == true) {
                          final result = await _songRepository.getSongs();
                          if (result.isSuccess()) {
                            final allSongs = result.getOrThrow();
                            
                            final updatedSong = allSongs.firstWhere((s) => s.id == currentSong.id);
                            
                            setState(() {
                              _localPlaylist[_currentIndex] = updatedSong;
                            });
                          }
                        }
                      } else if (choice == 'equalizer') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EqualizerScreen(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Edit song info'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'equalizer',
                        child: Row(
                          children: [
                            Icon(Icons.tune_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Equalizer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: PlayerSettings(
                    child: Column(
                      children: [
                        // --- REPLACED: GestureDetector with PageView.builder ---
                        SizedBox(
                          height: 300,
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _localPlaylist.length,
                            onPageChanged: (newIndex) {
                              // Triggers the song change when the user finishes swiping
                              if (_currentIndex != newIndex) {
                                _audioPlayer.seek(Duration.zero, index: newIndex);
                              }
                            },
                            itemBuilder: (context, index) {
                              final song = _localPlaylist[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: double.infinity,
                                    color: Theme.of(context).cardTheme.color,
                                    child: song.imagePath != null
                                        ? Image.file(File(song.imagePath!), fit: BoxFit.cover)
                                        : const Icon(Icons.album, size: 100),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(songTitle, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(artistName, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleFavorite,
                              child: Icon(
                                currentSong.favorite ? Icons.favorite : Icons.favorite_border,
                                color: currentSong.favorite ? Colors.red : Colors.grey,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Album: $albumName', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(_formatDuration(_currentPosition)),
                  GestureDetector(
                    onTap: _toggleShuffle,
                    child: Icon(Icons.shuffle, color: _isShuffle ? Theme.of(context).primaryColor : Colors.grey),
                  ),
                  GestureDetector(
                    onTap: _toggleRepeat,
                    child: Icon(
                      _loopMode == LoopMode.one ?  Icons.repeat_one: Icons.repeat,
                      color: _loopMode != LoopMode.off ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                  Text(_formatDuration(_totalDuration)),
                ],
              ),
              Slider(
                min: 0.0,
                max: _totalDuration > 0 ? _totalDuration : 1.0,
                value: _currentPosition.clamp(0.0, _totalDuration > 0 ? _totalDuration : 1.0),
                onChanged: (value) => _audioPlayer.seek(Duration(milliseconds: value.toInt())),
              ),
              Row(
                children: [
                  Expanded(child: GestureDetector(onTap: _skipPrevious, child: const PlayerSettings(child: Icon(Icons.skip_previous)))),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: GestureDetector(onTap: _togglePlayPause, child: PlayerSettings(child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 32)))),
                  const SizedBox(width: 20),
                  Expanded(child: GestureDetector(onTap: _skipNext, child: const PlayerSettings(child: Icon(Icons.skip_next)))),
                ],
              ),
              
              const SizedBox(height: 30),
              
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.lyrics_outlined),
                  label: const Text(
                    'SHOW LYRICS', 
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)
                  ),
                  onPressed: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LyricsScreen(song: currentSong, songRepository: _songRepository),
                        ),
                      );
                    } catch (e, stackTrace) {
                      debugPrint('NAVIGATION CRASH: $e');
                      debugPrint('STACK TRACE:\n$stackTrace');
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ), 
    );
  }
}