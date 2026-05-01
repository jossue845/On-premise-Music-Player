import 'package:flutter/material.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:sqflite/sqflite.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;
  
  const AlbumDetailScreen({super.key, required this.albumName});

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
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);
    
    try {
      // Fetch all songs
      final result = await _songRepository.getSongs();
      if (result.isSuccess()) {
        final allSongs = result.getOrThrow();
        
        setState(() {
          // Filter to only include songs from this specific album
          _songs = allSongs.where((song) => song.album == widget.albumName).toList();
          
          // Sort them by their official track number so the album plays in order!
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
      body: _isLoading
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
                      // Show the track number if available, otherwise just use the list index
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
                    // Pulls the soft grey text style from your global theme for the duration
                    trailing: Text(
                      '--:--', // Placeholder until duration is added to the database model
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      // FIXED: Passes the entire album tracklist and the tapped index!
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            playlist: _songs,
                            initialIndex: index,
                          )
                        )
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}