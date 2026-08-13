import 'package:flutter/material.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/services/filesystem_service.dart';
import 'package:music_player_app/data/repositories/music_folder_repository.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/presentation/screens/equalizer_screen.dart';
import 'package:sqflite/sqflite.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isScanning = false;
  bool _isFetchingArt = false;
  String _scanStatus = '';
  late MusicFolderRepository _musicFolderRepository;
  late DatabaseService _databaseService;
  late FilesystemService _filesystemService;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(databaseFactory: databaseFactory);
    _filesystemService = FilesystemService();
    _musicFolderRepository = MusicFolderRepository(
      database: _databaseService,
      fs: _filesystemService,
    );
  }

  Future<void> _scanMusic() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning for music...';
    });

    try {
      final result = await _musicFolderRepository.scanFolder();
      
      if (result.isSuccess()) {
        setState(() {
          _isScanning = false;
          _scanStatus = 'Scan completed successfully!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Music scan completed!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = result.exceptionOrNull();
        setState(() {
          _isScanning = false;
          _scanStatus = 'Error: ${error?.toString() ?? 'Unknown error'}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: ${error?.toString() ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanStatus = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setSongsFolder() async {
    try {
      final result = await _musicFolderRepository.setMusicFolder();
      
      if (result.isSuccess()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Music folder set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = result.exceptionOrNull();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error?.toString() ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Automated Artwork Fetching Pipeline ---
  Future<void> _scanForMissingArtwork() async {
    setState(() => _isFetchingArt = true);
    
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    final songRepo = SongRepository(database: databaseService);
    
    try {
      final result = await songRepo.getSongs();
      if (result.isSuccess()) {
        final songs = result.getOrThrow();
        
        // Loop through all songs and target the ones missing images
        for (var song in songs) {
          if (song.imagePath == null || song.imagePath!.isEmpty) {
            await songRepo.fetchAndSaveMissingArtwork(song);
          }
        }
      }
    } catch (_) {}
    
    if (mounted) {
      setState(() => _isFetchingArt = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finished scanning for missing artwork!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          children: [
            // Scan for music
            Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 25),
              child: ListTile(
                title: const Text("Look for new music"), // Scan songs
                subtitle: _scanStatus.isNotEmpty 
                    ? Text(
                        _scanStatus,
                        style: TextStyle(
                          color: _scanStatus.contains('Error') ? Colors.red : Colors.green,
                        ),
                      )
                    : null,
                onTap: _isScanning ? null : _scanMusic,
                enabled: !_isScanning,
                trailing: _isScanning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.music_note),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 25),
              child: ListTile(
                title: const Text("Songs folder"), // Define where the songs are going to be
                subtitle: const Text("Set the folder to scan for music"),
                onTap: _setSongsFolder,
                trailing: const Icon(Icons.folder),
              ),
            ),

            // --- NEW: Fetch Missing Artwork Trigger ---
            Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 25),
              child: ListTile(
                title: const Text('Fetch Missing Album Art'),
                subtitle: const Text('Searches MusicBrainz & Cover Art Archive'),
                onTap: _isFetchingArt ? null : _scanForMissingArtwork,
                trailing: _isFetchingArt 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ) 
                    : const Icon(Icons.image_search),
              ),
            ),
                        
            // Equalizer
            Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 25),
              child: ListTile(
                title: const Text("Equalizer"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EqualizerScreen(),
                    ),
                  ); 
                },
                trailing: const Icon(Icons.equalizer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}