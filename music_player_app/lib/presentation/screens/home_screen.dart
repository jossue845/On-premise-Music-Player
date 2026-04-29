import 'package:flutter/material.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:sqflite/sqflite.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  late SongRepository _songRepository;
  List<Song> _allSongs = [];
  List<Song> _recentSongs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSongRepository();
    _loadSongs();
  }

  void _initializeSongRepository() {
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _songRepository.getSongs();
      if (result.isSuccess()) {
        final songs = result.getOrThrow();
        setState(() {
          _allSongs = songs;
          // Take last 5 songs as "recent"
          _recentSongs = songs.length > 5 
              ? songs.sublist(songs.length - 5) 
              : songs;
          _isLoading = false;
        });
      } else {
        final error = result.exceptionOrNull();
        print('Error loading songs: $error');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Exception loading songs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- 1. LAST PLAYED ---
          const Text('Last Played', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10), 
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recentSongs.isNotEmpty
                  ? Card(
                      child: ListTile(
                        leading: const Icon(Icons.music_note, size: 40),
                        title: Text(
                          _recentSongs.last.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _recentSongs.last.artists.isNotEmpty 
                              ? _recentSongs.last.artists.first 
                              : 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(song: _recentSongs.last),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.play_circle_fill, size: 36),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerScreen(song: _recentSongs.last),
                              ),
                            );
                          },
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

          // --- 2. DAILY STATS ---
          const Text('Daily Stats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(context, 'Time Listened', '2h 14m', Icons.timer),
              const SizedBox(width: 16), 
              _buildStatCard(context, 'Tracks', '${_allSongs.length}', Icons.bar_chart),
            ],
          ),
          const SizedBox(height: 24),

          // --- 3. MOST REPRODUCED ---
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
                                    builder: (context) => PlayerScreen(song: song),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 120,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.album, size: 50),
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

  // Updated helper method to require BuildContext
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dynamically pulls the glowing Cyan accent from your AppTheme
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              // Pulls the soft grey label style directly from your AppTheme typography
              Text(title, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}