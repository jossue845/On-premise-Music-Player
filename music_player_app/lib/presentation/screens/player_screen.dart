import 'dart:async';
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
  final SongRepository? testSongRepository; 
  final bool isSidePanel;
  final VoidCallback? onClose;

  const PlayerScreen({
    super.key, 
    required this.playlist, 
    required this.initialIndex,
    this.testSongRepository, 
    this.isSidePanel = false,
    this.onClose,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late SongRepository _songRepository;
  late List<Song> _localPlaylist;
  late AudioPlayer _audioPlayer;
  
  late PageController _pageController;
  late DateTime _initTime; 
  
  bool _isPlaying = false;
  double _currentPosition = 0.0;
  double _totalDuration = 1.0; 
  bool _isShuffle = false;
  late LoopMode _loopMode; 
  late int _currentIndex;

  StreamSubscription? _currentIndexSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  @override
  void initState() {
    super.initState();
    _initTime = DateTime.now(); 
    
    _audioPlayer = ref.read(audioPlayerProvider);
    _loopMode = _audioPlayer.loopMode; 
    
    _currentIndex = widget.initialIndex;
    _localPlaylist = List.from(widget.playlist);
    
    _pageController = PageController(initialPage: widget.initialIndex);
    
    if (widget.testSongRepository != null) {
      _songRepository = widget.testSongRepository!;
    } else {
      final databaseService = DatabaseService(databaseFactory: databaseFactory);
      _songRepository = SongRepository(database: databaseService);
    }
    
    _setupStreams();
    
    if (!widget.isSidePanel) {
      _initPlayer();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(widget.initialIndex);
        }
      });
    }
  }

  // Fix: adedd didupdatewidget to force the UI to sncy when the parent changes the track index
  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playlist != oldWidget.playlist) {
      _localPlaylist = List.from(widget.playlist);
    }
    if (widget.initialIndex != oldWidget.initialIndex) {
      if (_currentIndex != widget.initialIndex) {
        setState(() => _currentIndex = widget.initialIndex);
        if (_pageController.hasClients) {
          _pageController.jumpToPage(widget.initialIndex);
        }
      }
    }
  }

  Future<void> _initPlayer() async {
    if (_localPlaylist.isEmpty) return;
    
    final targetSong = _localPlaylist[widget.initialIndex];
    final currentTag = _audioPlayer.sequenceState?.currentSource?.tag as MediaItem?;
    final isAlreadyPlaying = currentTag?.id == targetSong.id.toString();

    if (!isAlreadyPlaying) {
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
      } else {
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
    } else {
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
    }

    if (_pageController.hasClients && _pageController.page?.round() != widget.initialIndex) {
      _pageController.jumpToPage(widget.initialIndex);
    }
  }

  void _setupStreams() {
    _currentIndexSub = _audioPlayer.currentIndexStream.listen((index) {
      if (mounted && index != null) {
        final sequence = _audioPlayer.sequenceState?.sequence;
        if (sequence != null && index < sequence.length) {
          final tag = sequence[index].tag as MediaItem?;
          if (tag != null) {
            final matchedIndex = _localPlaylist.indexWhere((s) => s.id.toString() == tag.id);
            if (matchedIndex != -1) {
              setState(() => _currentIndex = matchedIndex);
              
              if (_pageController.hasClients) {
                final currentPage = _pageController.page?.round() ?? widget.initialIndex;
                if (currentPage != matchedIndex) {
                  _pageController.animateToPage(
                    matchedIndex, 
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeOutCubic,
                  );
                }
              }
            }
          }
        }
      }
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });

    _positionSub = _audioPlayer.positionStream.listen((position) {
      if (mounted) setState(() => _currentPosition = position.inMilliseconds.toDouble());
    });

    _durationSub = _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) setState(() => _totalDuration = duration.inMilliseconds.toDouble());
    });
  }

  @override
  void dispose() {
    _currentIndexSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _backScreen(BuildContext context) => Navigator.pop(context);

  void _togglePlayPause() async {
    _audioPlayer.playing ? await _audioPlayer.pause() : await _audioPlayer.play();
  }

  void _skipNext() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    } else {
      await _audioPlayer.seek(Duration.zero, index: 0);
    }
  }

  void _skipPrevious() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    } else {
      await _audioPlayer.seek(Duration.zero, index: _localPlaylist.length - 1);
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

    final topBar = Row(
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EqualizerScreen()));
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
    );

    Widget buildAlbumArt(double height) {
      return SizedBox(
        height: height,
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          itemCount: _localPlaylist.length,
          onPageChanged: (newIndex) {
            if (DateTime.now().difference(_initTime).inMilliseconds < 500) return;
            
            final targetSong = _localPlaylist[newIndex];
            final audioSequence = _audioPlayer.sequenceState?.sequence ?? [];
            
            final sequenceIndex = audioSequence.indexWhere((item) => (item.tag as MediaItem?)?.id == targetSong.id.toString());
            
            if (sequenceIndex != -1 && _audioPlayer.currentIndex != sequenceIndex) {
              _audioPlayer.seek(Duration.zero, index: sequenceIndex);
            }
          },
          itemBuilder: (context, index) {
            final song = _localPlaylist[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Theme.of(context).cardTheme.color,
                      child: song.imagePath != null
                          ? Image.file(File(song.imagePath!), fit: BoxFit.cover)
                          : const Icon(Icons.album, size: 100),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    final songInfo = Row(
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
    );

    final albumText = Text('Album: $albumName', style: Theme.of(context).textTheme.bodySmall);

    final progressRow = Row(
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
            _loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
            color: _loopMode != LoopMode.off ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
        Text(_formatDuration(_totalDuration)),
      ],
    );

    final sliderWidget = Slider(
      min: 0.0,
      max: _totalDuration > 0 ? _totalDuration : 1.0,
      value: _currentPosition.clamp(0.0, _totalDuration > 0 ? _totalDuration : 1.0),
      onChanged: (value) => _audioPlayer.seek(Duration(milliseconds: value.toInt())),
    );

    final mainControls = Row(
      children: [
        Expanded(child: GestureDetector(onTap: _skipPrevious, child: const PlayerSettings(child: Icon(Icons.skip_previous)))),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: GestureDetector(onTap: _togglePlayPause, child: PlayerSettings(child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 32)))),
        const SizedBox(width: 20),
        Expanded(child: GestureDetector(onTap: _skipNext, child: const PlayerSettings(child: Icon(Icons.skip_next)))),
      ],
    );

    final lyricsButton = Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        icon: const Icon(Icons.lyrics_outlined),
        label: const Text('SHOW LYRICS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        onPressed: () {
          try {
            Navigator.push(context, MaterialPageRoute(builder: (context) => LyricsScreen(song: currentSong, songRepository: _songRepository)));
          } catch (e, stackTrace) {
            debugPrint('NAVIGATION CRASH: $e');
            debugPrint('STACK TRACE:\n$stackTrace');
          }
        },
      ),
    );

    Widget panelHeader = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Now Playing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
      ],
    );

    if (widget.isSidePanel) {
      return Container(
        width: 340,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: const Border(left: BorderSide(color: Colors.white24, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: SafeArea(
          child: Column(
            children: [
              panelHeader,
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: PlayerSettings(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildAlbumArt(280),
                        const SizedBox(height: 15),
                        songInfo,
                        const SizedBox(height: 8),
                        albumText,
                        const SizedBox(height: 24),
                        progressRow,
                        sliderWidget,
                        mainControls,
                        const SizedBox(height: 30),
                        lyricsButton,
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
                return Column(
                  children: [
                    topBar,
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: PlayerSettings(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildAlbumArt(300),
                              const SizedBox(height: 15),
                              songInfo,
                              const SizedBox(height: 16),
                              albumText,
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    progressRow,
                    sliderWidget,
                    mainControls,
                    const SizedBox(height: 30),
                    lyricsButton,
                    const SizedBox(height: 20),
                  ],
                );
              } else {
                return Column(
                  children: [
                    topBar,
                    const SizedBox(height: 10),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: buildAlbumArt(MediaQuery.of(context).size.height * 0.7),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 6,
                            child: Center(
                              child: SingleChildScrollView(
                                child: PlayerSettings(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      songInfo,
                                      const SizedBox(height: 8),
                                      albumText,
                                      const SizedBox(height: 20),
                                      progressRow,
                                      sliderWidget,
                                      mainControls,
                                      const SizedBox(height: 20),
                                      lyricsButton,
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}