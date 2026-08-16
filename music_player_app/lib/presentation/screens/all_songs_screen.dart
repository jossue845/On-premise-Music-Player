import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:music_player_app/presentation/screens/edit_song_screen.dart';

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
              : RefreshIndicator(
                  onRefresh: _initializeRepositoryAndLoad,
                  color: Theme.of(context).primaryColor,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (String choice) async {
                              if (choice == 'edit') {
                                final didUpdate = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditSongScreen(song: song)),
                                );
                                
                                if (didUpdate == true) {
                                  _initializeRepositoryAndLoad(); 
                                }
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
                            ],
                          ),
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
                                builder: (context) => PlayerScreen(
                                  playlist: _songs,
                                  initialIndex: index,
                                ), // FIX: Added the missing closing parenthesis here
                              ),
                            ).then((_) => _initializeRepositoryAndLoad()); 
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}