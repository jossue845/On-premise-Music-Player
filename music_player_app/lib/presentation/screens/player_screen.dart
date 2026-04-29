import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // Make sure this is in your pubspec.yaml!
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/components/player_settings.dart'; 

class PlayerScreen extends StatefulWidget {
  final Song? song;

  const PlayerScreen({super.key, this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // --- 1. The Audio Engine ---
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  double _currentPosition = 0.0;
  double _totalDuration = 1.0; // Default to 1 to prevent Slider math errors
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  // --- 2. Load the physical file and listen to the engine ---
  Future<void> _initPlayer() async {
    if (widget.song != null) {
      try {
        debugPrint("▶️ PLAYER: Attempting to load file at: ${widget.song!.path}");
        
        // Using Uri.file safely encodes spaces and special characters
        final audioUri = Uri.file(widget.song!.path);
        
        // Feed the file to just_audio
        await _audioPlayer.setAudioSource(AudioSource.uri(audioUri));
        debugPrint("▶️ PLAYER: File loaded successfully!");

        // Listen to the play/pause state
        _audioPlayer.playerStateStream.listen((state) {
          if (mounted) {
            setState(() => _isPlaying = state.playing);
          }
        });

        // Listen to the playback position to update the slider
        _audioPlayer.positionStream.listen((position) {
          if (mounted) {
            setState(() => _currentPosition = position.inMilliseconds.toDouble());
          }
        });

        // Get the total duration of the track
        _audioPlayer.durationStream.listen((duration) {
          if (mounted && duration != null) {
            setState(() => _totalDuration = duration.inMilliseconds.toDouble());
          }
        });

        // Auto-play when the screen opens
        debugPrint("▶️ PLAYER: Issuing play command...");
        await _audioPlayer.play();
        
      } catch (e) {
        debugPrint("❌ PLAYER ERROR: Failed to load or play audio: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error playing audio: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // ALWAYS dispose the player to prevent memory leaks!
    _audioPlayer.dispose();
    super.dispose();
  }

  void _backScreen(BuildContext context) {
    Navigator.pop(context);
  }

  // --- 3. The Hardware Controls ---
  void _togglePlayPause() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("❌ PLAYER ERROR during toggle: $e");
    }
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
    });
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeat = !_isRepeat;
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _skipNext() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Next: Skipped to next song')),
    );
  }

  void _skipPrevious() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Previous: Skipped to previous song')),
    );
  }

  // Helper to format milliseconds into 0:00 text
  String _formatDuration(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Use song data if provided, otherwise show placeholder
    final String songTitle = widget.song?.title ?? 'Unknown Song';
    final String artistName = widget.song?.artists.isNotEmpty == true 
        ? widget.song!.artists.first 
        : 'Unknown Artist';
    final String albumName = widget.song?.album ?? 'Album';

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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Menu options coming soon')),
                      );
                    }, 
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
                        // Album artwork
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            color: Theme.of(context).cardTheme.color,
                            child: widget.song?.imagePath != null
                                ? Image.file(
                                    File(widget.song!.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.album, size: 100),
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Song, Artist, and favorite
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

              // --- 4. DYNAMIC PROGRESS BAR & TIMESTAMPS ---
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
                      Icons.repeat,
                      color: _isRepeat ? Theme.of(context).primaryColor : Colors.grey,
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
                  // Actually seek the audio hardware when the user drags the slider
                  _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),

              Row(
                children: [
                  // skip previous
                  Expanded(
                    child: GestureDetector(
                      onTap: _skipPrevious,
                      child: const PlayerSettings(
                        child: Icon(Icons.skip_previous),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // play pause
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
                  
                  // skip forward
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