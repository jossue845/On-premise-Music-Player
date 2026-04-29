import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:sqflite/sqflite.dart';

class AllSongsScreen extends StatefulWidget {
  const AllSongsScreen({super.key});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  late SongRepository _songRepository;
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeRepositoryAndLoad();
  }

  Future<void> _initializeRepositoryAndLoad() async {
    setState(() => _isLoading = true);
    
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);
    
    try {
      final result = await _songRepository.getSongs();
      if (result.isSuccess()) {
        final fetchedSongs = result.getOrThrow();
        
        // THIS WILL PRINT TO YOUR DEBUG CONSOLE:
        debugPrint("🎵 DATABASE CHECK: Found ${fetchedSongs.length} songs!");
        
        setState(() {
          _songs = fetchedSongs;
          _isLoading = false;
        });
      } else {
        debugPrint("🎵 DATABASE ERROR: ${result.exceptionOrNull()}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("🎵 EXCEPTION CAUGHT: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Songs', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No songs found.'),
                      TextButton(
                        onPressed: _initializeRepositoryAndLoad,
                        child: const Text('Tap here to refresh'),
                      )
                    ],
                  ),
                )
              // Wrap the list in a RefreshIndicator!
              : RefreshIndicator(
                  onRefresh: _initializeRepositoryAndLoad,
                  color: Theme.of(context).primaryColor,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even if list is short
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: song.imagePath != null
                                  ? Image.file(File(song.imagePath!), fit: BoxFit.cover)
                                  : const Icon(Icons.music_note),
                            ),
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            song.artists.isNotEmpty ? song.artists.first : 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerScreen(song: song),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}