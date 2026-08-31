import 'package:flutter/material.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:sqflite/sqflite.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;
  
  // --- NEW: Testing Parameter ---
  final DatabaseService? testDatabaseService;

  const AlbumDetailScreen({
    super.key, 
    required this.albumName,
    this.testDatabaseService,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late SongRepository _songRepository;
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumTracks();
  }

  Future<void> _loadAlbumTracks() async {
    setState(() => _isLoading = true);
    
    // --- FIX: Use injected mock database if provided ---
    final databaseService = widget.testDatabaseService ?? DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);
    
    try {
      final result = await _songRepository.getSongs();
      if (result.isSuccess()) {
        final allSongs = result.getOrThrow();
        
        setState(() {
          _songs = allSongs.where((song) => song.album == widget.albumName).toList();
          _songs.sort((a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading album tracks: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _songs.isEmpty
              ? Center(child: Text('No tracks found for ${widget.albumName}.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: Text(
                          song.trackNumber?.toString() ?? '${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          song.title, 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '--:--', 
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(
                                playlist: _songs,
                                initialIndex: index,
                                // --- FIX: Propagate the test database to the Player ---
                                testDatabaseService: widget.testDatabaseService,
                              )
                            )
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}