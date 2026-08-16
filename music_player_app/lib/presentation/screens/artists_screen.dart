import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/presentation/screens/sartist_screen.dart'; // FIX: Corrected import typo
import 'package:sqflite/sqflite.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  late SongRepository _songRepository;
  
  List<String> _artists = [];
  Map<String, String?> _artistImages = {}; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);

    try {
      final result = await _songRepository.getSongs();
      if (result.isSuccess()) {
        final songs = result.getOrThrow();
        
        final Set<String> artistSet = {};
        final Map<String, String?> imageMap = {};

        for (final song in songs) {
          final artists = song.artists.isNotEmpty ? song.artists : ['Unknown Artist'];
          
          for (final artist in artists) {
            artistSet.add(artist);
            
            if (song.imagePath != null && !imageMap.containsKey(artist)) {
              imageMap[artist] = song.imagePath;
            }
          }
        }

        setState(() {
          _artists = artistSet.toList()..sort(); 
          _artistImages = imageMap;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading artists: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _artists.isEmpty
              ? const Center(child: Text('No artists found. Scan for music in Settings.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _artists.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.85, 
                  ),
                  itemBuilder: (context, index) {
                    final artistName = _artists[index];
                    final imagePath = _artistImages[artistName];

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArtistDetailScreen(artistName: artistName),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: imagePath != null
                                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                                    : Icon(
                                        Icons.person, 
                                        size: 50,
                                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                artistName,
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