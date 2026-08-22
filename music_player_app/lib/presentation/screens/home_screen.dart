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
import 'package:music_player_app/presentation/screens/listening_habits_screen.dart';
import 'package:music_player_app/presentation/screens/sartist_screen.dart';
import 'package:music_player_app/presentation/screens/salbum_screen.dart';

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

  bool _isPlaying = false;
  
  int _secondsListened = 0;
  int _favoritesCount = 0;
  int _playlistCount = 0;
  Timer? _playbackTimer;

  StreamSubscription? _playerStateSubscription;

  String _topDay = 'Loading...';
  String _peakTime = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadSongs();
    _loadPlaylists();
    _loadTotalTime(); 
    _loadListeningHabits();
    _setupAudioStreams();
  }

  @override
  void dispose() {
    _stopTimer();
    _playerStateSubscription?.cancel();
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
        if (mounted) setState(() => _secondsListened = int.tryParse(result.getOrThrow()) ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _loadListeningHabits() async {
    try {
      final result = await _databaseService.getListeningHabits();
      if (result.isSuccess()) {
        final data = result.getOrThrow();
        if (mounted) {
          setState(() {
            _topDay = data['topDay'] ?? 'Not enough data';
            _peakTime = data['peakTime'] ?? 'Not enough data';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPlaylists() async {
    try {
      if (!_databaseService.isOpen()) {
        await _databaseService.open();
      }
      final result = await _databaseService.getPlaylists();
      if (result.isSuccess()) {
        if (mounted) {
          setState(() => _playlistCount = result.getOrThrow().length);
        }
      }
    } catch (e) {
      debugPrint("Error loading playlist count: $e");
    }
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final result = await _songRepository.getSongs();
      if (result.isSuccess()) {
        final songs = result.getOrThrow();

        if (mounted) {
          setState(() {
            _allSongs = songs;
            _favoritesCount = songs.where((s) => s.favorite).length;
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
          _isPlaying ? _startTimer() : _stopTimer();
        });
        if (state.processingState == ProcessingState.completed) _loadSongs(); 
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

  List<Map<String, dynamic>> get _topArtists {
    final Map<String, Map<String, dynamic>> artistsData = {};
    for (var song in _allSongs) {
      final artist = (song.artists.isNotEmpty && song.artists.first.trim().isNotEmpty) ? song.artists.first.trim() : 'Unknown Artist';
      if (artist == 'Unknown Artist' || artist == 'Unknown') continue;

      if (!artistsData.containsKey(artist)) {
        artistsData[artist] = {'name': artist, 'plays': 0, 'image': song.imagePath};
      }
      artistsData[artist]!['plays'] += song.playCount;
      artistsData[artist]!['image'] ??= song.imagePath; 
    }
    
    final sorted = artistsData.values.toList()..sort((a, b) => (b['plays'] as int).compareTo(a['plays'] as int));
    return sorted.where((a) => (a['plays'] as int) > 0).toList();
  }

  List<Map<String, dynamic>> get _topAlbums {
    final Map<String, Map<String, dynamic>> albumsData = {};
    for (var song in _allSongs) {
      final album = (song.album.trim().isNotEmpty) ? song.album.trim() : 'Unknown Album';
      if (album == 'Unknown Album') continue;

      if (!albumsData.containsKey(album)) {
        albumsData[album] = {'name': album, 'artist': song.artists.isNotEmpty ? song.artists.first : '', 'plays': 0, 'image': song.imagePath};
      }
      albumsData[album]!['plays'] += song.playCount;
      albumsData[album]!['image'] ??= song.imagePath;
    }
    
    final sorted = albumsData.values.toList()..sort((a, b) => (b['plays'] as int).compareTo(a['plays'] as int));
    return sorted.where((a) => (a['plays'] as int) > 0).toList();
  }

  String get _formattedTime {
    final hours = _secondsListened ~/ 3600;
    final minutes = (_secondsListened % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m ${_secondsListened % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 100.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true, 
            snap: true, 
            elevation: 0,
            toolbarHeight: 10,
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: bottomPadding, left: 16.0, right: 16.0, top: 8.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                // --- DAILY STATS OVERVIEW ---
                const Text('Quick Stats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // --- FIX: Replaced Wrap with SingleChildScrollView for horizontal scrolling ---
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none, // Allows card shadows to render properly while scrolling
                  child: Row(
                    children: [
                      _buildStatCard(context, 'Listened', _formattedTime, Icons.timer),
                      const SizedBox(width: 16),
                      _buildStatCard(context, 'Total Tracks', '${_allSongs.length}', Icons.library_music),
                      const SizedBox(width: 16),
                      _buildStatCard(context, 'Favorites', '$_favoritesCount', Icons.favorite),
                      const SizedBox(width: 16),
                      _buildStatCard(context, 'Playlists', '$_playlistCount', Icons.queue_music),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- MOST REPRODUCED SONGS ---
                const Text('Top Tracks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final topPlayedSongs = List<Song>.from(_allSongs)..sort((a, b) => b.playCount.compareTo(a.playCount));
                    final activeTopSongs = topPlayedSongs.where((s) => s.playCount > 0).toList();
                    return _buildHorizontalScroller(
                      items: activeTopSongs,
                      isEmpty: activeTopSongs.isEmpty,
                      itemBuilder: (context, index) {
                        final song = activeTopSongs[index];
                        return _buildSquareCard(
                          context,
                          title: song.title,
                          subtitle: song.artists.isNotEmpty ? song.artists.first : 'Unknown',
                          imagePath: song.imagePath,
                          isRound: false,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(playlist: activeTopSongs, initialIndex: index))),
                        );
                      }
                    );
                  }
                ),
                const SizedBox(height: 24),

                // --- MOST REPRODUCED ARTISTS ---
                const Text('Top Artists', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final topArtists = _topArtists;
                    return _buildHorizontalScroller(
                      items: topArtists,
                      isEmpty: topArtists.isEmpty,
                      itemBuilder: (context, index) {
                        final artist = topArtists[index];
                        return _buildSquareCard(
                          context,
                          title: artist['name'],
                          subtitle: '${artist['plays']} plays',
                          imagePath: artist['image'],
                          isRound: true, 
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArtistDetailScreen(
                                  artistName: artist['name'],
                                ),
                              ),
                            );
                          }, 
                        );
                      }
                    );
                  }
                ),
                const SizedBox(height: 24),

                // --- MOST REPRODUCED ALBUMS ---
                const Text('Top Albums', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final topAlbums = _topAlbums;
                    return _buildHorizontalScroller(
                      items: topAlbums,
                      isEmpty: topAlbums.isEmpty,
                      itemBuilder: (context, index) {
                        final album = topAlbums[index];
                        return _buildSquareCard(
                          context,
                          title: album['name'],
                          subtitle: album['artist'],
                          imagePath: album['image'],
                          isRound: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlbumDetailScreen(
                                  albumName: album['name'],
                                ),
                              ),
                            );
                          }, 
                        );
                      }
                    );
                  }
                ),
                const SizedBox(height: 32),

                // --- TRACK YOUR STATS WIDGET ---
                const Text('Listening Habits', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft, 
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500), 
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16), 
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ListeningHabitsScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.blueAccent),
                                  const SizedBox(width: 12),
                                  const Text('Peak Time: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Expanded(
                                    child: Text(
                                      _peakTime, 
                                      style: const TextStyle(fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 30),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.deepPurpleAccent),
                                  const SizedBox(width: 12),
                                  const Text('Top Day: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Expanded(
                                    child: Text(
                                      _topDay, 
                                      style: const TextStyle(fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (_topDay == 'Not enough data') ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "Play more music to generate your habits profile!",
                                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareCard(BuildContext context, {required String title, required String subtitle, String? imagePath, required bool isRound, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      clipBehavior: Clip.antiAlias, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isRound ? 16 : 8)),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(isRound ? 60 : 4.0),
                child: Container(
                  width: 70,
                  height: 70,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: imagePath != null
                      ? Image.file(File(imagePath), fit: BoxFit.cover)
                      : Icon(isRound ? Icons.person : Icons.album, size: 30, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalScroller({required List items, required bool isEmpty, required Widget Function(BuildContext, int) itemBuilder}) {
    return SizedBox(
      height: 140, 
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
              ? const Center(child: Text('Play some music to populate this list!'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length.clamp(0, 10),
                  itemBuilder: itemBuilder,
                ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 200),
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