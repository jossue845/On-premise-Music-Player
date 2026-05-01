import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/components/player_settings.dart'; 

class PlayerScreen extends StatefulWidget {
  // We now require the full playlist and the index of the tapped song
  final List<Song> playlist;
  final int initialIndex;

  const PlayerScreen({
    super.key, 
    required this.playlist, 
    required this.initialIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  double _currentPosition = 0.0;
  double _totalDuration = 1.0; 
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  bool _isFavorite = false;
  
  // Track the currently playing index so the UI updates
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.playlist.isNotEmpty) {
      try {
        // 1. Convert our list of 'Song' models into just_audio 'AudioSources'
        final audioSources = widget.playlist.map((song) {
          return AudioSource.uri(Uri.file(song.path));
        }).toList();

        // 2. Create a playlist out of those sources
        final playlistSource = ConcatenatingAudioSource(children: audioSources);

        // 3. Feed the playlist to the player and tell it where to start
        await _audioPlayer.setAudioSource(
          playlistSource,
          initialIndex: widget.initialIndex,
        );

        // Listen to the current index so we know when a song changes
        _audioPlayer.currentIndexStream.listen((index) {
          if (mounted && index != null) {
            setState(() {
              _currentIndex = index;
              _currentPosition = 0.0; // Reset slider
            });
          }
        });

        _audioPlayer.playerStateStream.listen((state) {
          if (mounted) setState(() => _isPlaying = state.playing);
        });

        _audioPlayer.positionStream.listen((position) {
          if (mounted) {
            setState(() => _currentPosition = position.inMilliseconds.toDouble());
          }
        });

        _audioPlayer.durationStream.listen((duration) {
          if (mounted && duration != null) {
            setState(() => _totalDuration = duration.inMilliseconds.toDouble());
          }
        });

        await _audioPlayer.play();
        
      } catch (e) {
        debugPrint("PLAYER ERROR: $e");
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _backScreen(BuildContext context) => Navigator.pop(context);

  void _togglePlayPause() async {
    _audioPlayer.playing ? await _audioPlayer.pause() : await _audioPlayer.play();
  }

  void _skipNext() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    }
  }

  void _skipPrevious() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    } else {
      await _audioPlayer.seek(Duration.zero); // Restart song if it's the first one
    }
  }

  void _toggleShuffle() async {
    setState(() => _isShuffle = !_isShuffle);
    await _audioPlayer.setShuffleModeEnabled(_isShuffle);
  }

  void _toggleRepeat() async {
    LoopMode nextMode;
    switch (_loopMode) {
      case LoopMode.off:
        nextMode = LoopMode.all;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repeat: All'), duration: Duration(seconds: 1)));
        break;
      case LoopMode.all:
        nextMode = LoopMode.one;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repeat: Track'), duration: Duration(seconds: 1)));
        break;
      case LoopMode.one:
        nextMode = LoopMode.off;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repeat: Off'), duration: Duration(seconds: 1)));
        break;
  }
  
  setState(() {
      _loopMode = nextMode;
    });
    await _audioPlayer.setLoopMode(nextMode);
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    // TODO: Update favorite status in database
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
    // Grab the current song dynamically based on the index!
    final currentSong = widget.playlist[_currentIndex];
    
    final String songTitle = currentSong.title;
    final String artistName = currentSong.artists.isNotEmpty ? currentSong.artists.first : 'Unknown Artist';
    final String albumName = currentSong.album;

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
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.menu)
                  ),
                ],
              ),
              
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: PlayerSettings(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            color: Theme.of(context).cardTheme.color,
                            child: currentSong.imagePath != null
                                ? Image.file(File(currentSong.imagePath!), fit: BoxFit.cover)
                                : const Icon(Icons.album, size: 100),
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
                                  Text(
                                    songTitle,
                                    style: Theme.of(context).textTheme.titleLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    artistName,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleFavorite,
                              child: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : Colors.grey,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Album: $albumName',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                    child: Icon(
                      Icons.shuffle,
                      color: _isShuffle ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleRepeat,
                    child: Icon(
                      _loopMode == LoopMode.one ?  Icons.repeat_one: Icons.repartition,
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
                onChanged: (value) {
                  _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _skipPrevious,
                      child: const PlayerSettings(
                        child: Icon(Icons.skip_previous),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: PlayerSettings(
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: _skipNext,
                      child: const PlayerSettings(
                        child: Icon(Icons.skip_next),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ), 
    );
  }
}