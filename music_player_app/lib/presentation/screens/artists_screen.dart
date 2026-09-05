import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/presentation/screens/sartist_screen.dart';
import 'package:sqflite/sqflite.dart';

class ArtistsScreen extends StatefulWidget {
  // Fix: Add dependency injection to facilitate widget testing
  final SongRepository? testSongRepository;

  const ArtistsScreen({super.key, this.testSongRepository});

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

  // Scans the local database for all available artists and extracts their associated cover art
  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);
    
    // Fix: Use the injected repository if available
    if (widget.testSongRepository != null) {
      _songRepository = widget.testSongRepository!;
    } else {
      final databaseService = DatabaseService(databaseFactory: databaseFactory);
      _songRepository = SongRepository(database: databaseService);
    }

    try {
      final result = await _songRepository.getSongs();
      
      if (result.isSuccess() == true) {
        final songs = result.getOrThrow();
        
        final Set<String> artistSet = {};
        final Map<String, String?> imageMap = {};

        for (int i = 0; i < songs.length; i++) {
          var song = songs[i];
          List<String> artists = [];
          
          if (song.artists.isNotEmpty == true) {
            artists = song.artists;
          } else {
            artists = ['Unknown Artist'];
          }
          
          for (int j = 0; j < artists.length; j++) {
            String artist = artists[j];
            artistSet.add(artist);
            
            bool hasImage = false;
            if (song.imagePath != null) {
              hasImage = true;
            }
            
            if (hasImage == true) {
              if (imageMap.containsKey(artist) == false) {
                imageMap[artist] = song.imagePath;
              }
            }
          }
        }

        setState(() {
          _artists = artistSet.toList()..sort(); 
          _artistImages = imageMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading artists: " + e.toString());
      setState(() {
        _isLoading = false;
      });
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final int columns = constraints.maxWidth >= 600 ? 4 : 2;
                    
                    return GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _artists.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
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
                                  builder: (context) => ArtistDetailScreen(
                                    artistName: artistName,
                                    // Fix: Pass the test repository down the navigation chain
                                    testSongRepository: _songRepository,
                                  ),
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
                    );
                  }
                ),
    );
  }
}