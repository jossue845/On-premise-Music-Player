import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:sqflite/sqflite.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistName;
  
  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  late SongRepository _songRepository;
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistSongs();
  }

  Future<void> _loadArtistSongs() async {
    setState(() => _isLoading = true);
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);
    
    try {
      final result = await _songRepository.getSongs();
      if (result.isSuccess()) {
        final allSongs = result.getOrThrow();
        
        setState(() {
          // FIXED: Safely handles "Unknown Artist" mapping
          _songs = allSongs.where((song) {
            if (widget.artistName == 'Unknown Artist' && song.artists.isEmpty) {
              return true;
            }
            return song.artists.contains(widget.artistName);
          }).toList();
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading artist songs: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artistName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _songs.isEmpty
          ? Center(child: Text('No songs found for ${widget.artistName}.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _songs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.85, 
              ),
              itemBuilder: (context, index) {
                final song = _songs[index];

                return Card(
                  clipBehavior: Clip.antiAlias, 
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: song.imagePath != null
                                ? Image.file(File(song.imagePath!), fit: BoxFit.cover)
                                : Icon(
                                    Icons.music_note, 
                                    size: 50, 
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5)
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            song.title, 
                            textAlign: TextAlign.center, 
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
