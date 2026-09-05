import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/services/filesystem_service.dart';
import 'package:music_player_app/data/repositories/music_folder_repository.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/presentation/screens/equalizer_screen.dart';
import 'package:music_player_app/presentation/screens/lastfm_screen.dart';
import 'package:sqflite/sqflite.dart';

import 'package:music_player_app/data/providers/sync_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final DatabaseService? testDatabaseService;
  final FilesystemService? testFilesystemService;
  final MusicFolderRepository? testMusicFolderRepository;
  final SongRepository? testSongRepository;

  const SettingsScreen({
    super.key,
    this.testDatabaseService,
    this.testFilesystemService,
    this.testMusicFolderRepository,
    this.testSongRepository,
  });

  @override
  ConsumerState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isScanning = false;
  bool _isFetchingArt = false;
  bool _isBatchValidating = false;
  bool _isSyncingLastFm = false; 
  bool _tiltEnabled = false;
  
  String _scanStatus = '';
  String _validationProgress = '';
  late MusicFolderRepository _musicFolderRepository;
  late DatabaseService _databaseService;
  late FilesystemService _filesystemService;

  @override
  void initState() {
    super.initState();
    _databaseService = widget.testDatabaseService ?? DatabaseService(databaseFactory: databaseFactory);
    _filesystemService = widget.testFilesystemService ?? FilesystemService();
    _musicFolderRepository = widget.testMusicFolderRepository ?? MusicFolderRepository(
      database: _databaseService,
      fs: _filesystemService,
    );
    _loadTiltSetting();
  }

  // Loads the user preference for the tilt control feature
  Future _loadTiltSetting() async {
    final res = await _databaseService.getValue('tilt_enabled');
    if (res.isSuccess() == true) {
      if (mounted == true) {
        String stringValue = res.getOrThrow();
        if (stringValue == 'true') {
          setState(() {
            _tiltEnabled = true;
          });
        } else {
          setState(() {
            _tiltEnabled = false;
          });
        }
      }
    }
  }

  // Scans the local filesystem for new audio files
  Future _scanMusic() async {
    setState(() { _isScanning = true; _scanStatus = 'Scanning for music...'; });
    try {
      final result = await _musicFolderRepository.scanFolder();
      final isSuccess = result.isSuccess();
      final errMsg = result.exceptionOrNull()?.toString() ?? 'Unknown error';
      
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanStatus = isSuccess ? 'Scan completed successfully!' : 'Error: $errMsg';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isSuccess ? 'Music scan completed!' : 'Scan failed: $errMsg'),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isScanning = false; _scanStatus = 'Error: $e'; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // Fix: Added explicit error handling and null checks for the set folder operation
  Future _setSongsFolder() async {
    try {
      final result = await _musicFolderRepository.setMusicFolder();
      
      if (result.isSuccess() == true) {
        if (mounted == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Music folder set successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = result.exceptionOrNull();
        String errorMessage = 'Unknown error';
        if (error != null) {
          errorMessage = error.toString();
        }
        
        if (mounted == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ' + errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ' + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Checks all songs in the library to see if they need album art downloaded
  Future _scanForMissingArtwork() async {
    setState(() {
      _isFetchingArt = true;
    });
    
    final songRepo = widget.testSongRepository ?? SongRepository(database: _databaseService);
    
    try {
      final result = await songRepo.getSongs();
      if (result.isSuccess() == true) {
        final songs = result.getOrThrow();
        
        for (int i = 0; i < songs.length; i++) {
          var song = songs[i];
          bool needsArtwork = false;
          
          if (song.imagePath == null) {
            needsArtwork = true;
          } else if (song.imagePath == '') {
            needsArtwork = true;
          }
          
          if (needsArtwork == true) {
            await songRepo.fetchAndSaveMissingArtwork(song);
          }
        }
      }
    } catch (e) {
      // Ignored catch block
    }
    
    if (mounted == true) {
      setState(() {
        _isFetchingArt = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finished scanning for missing artwork!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Fix: Optimized progress callback to only update when the widget is still mounted
  Future _batchValidateTags() async {
    setState(() { _isBatchValidating = true; _validationProgress = 'Starting validation...'; });
    final songRepo = widget.testSongRepository ?? SongRepository(database: _databaseService);
    
    final updatedCount = await songRepo.validateAndFixAllSongs(
      onProgress: (current, total) => mounted ? setState(() => _validationProgress = 'Validating $current of $total songs...') : null,
    );

    if (mounted) {
      setState(() { _isBatchValidating = false; _validationProgress = ''; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Batch validation complete! Updated $updatedCount tracks.'),
        backgroundColor: Colors.green,
      ));
    }
  }

  // Returns the correct trailing icon based on the current scan state
  Widget _getTrailingIconForScan() {
    if (_isScanning == true) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      return const Icon(Icons.music_note);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: SwitchListTile(
                  title: const Text("Tilt to Move Player"),
                  subtitle: const Text("Use device gyroscope to move the floating player"),
                  value: _tiltEnabled,
                  activeColor: Colors.cyanAccent,
                  // Saves the tilt setting to the database when toggled
                  onChanged: (val) async {
                    setState(() {
                      _tiltEnabled = val;
                    });
                    await _databaseService.insertKVPair('tilt_enabled', val.toString());
                  },
                  secondary: const Icon(Icons.screen_rotation),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: ListTile(
                  title: const Text("Look for new music"), 
                  subtitle: _scanStatus.isNotEmpty 
                      ? Text(_scanStatus, style: TextStyle(color: _scanStatus.contains('Error') ? Colors.red : Colors.green)) 
                      : null,
                  // Fix: Prevented onTap execution if a scan is already running
                  onTap: _isScanning ? null : _scanMusic,
                  enabled: !_isScanning,
                  trailing: _getTrailingIconForScan(),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: ListTile(
                  title: const Text("Songs folder"), 
                  subtitle: const Text("Set the folder to scan for music"),
                  onTap: _setSongsFolder,
                  trailing: const Icon(Icons.folder),
                ),
              ),
        
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: ListTile(
                  title: const Text('Auto-Fix All Metadata'),
                  subtitle: _isBatchValidating
                      ? Text(_validationProgress, style: const TextStyle(color: Colors.orangeAccent))
                      : const Text('Batch validate all track tags with TheAudioDB'),
                  onTap: _isBatchValidating ? null : _batchValidateTags,
                  trailing: _isBatchValidating
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_fix_high, color: Colors.orangeAccent),
                ),
              ),
                          
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: ListTile(
                  title: const Text("Equalizer"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EqualizerScreen(testDatabaseService: widget.testDatabaseService))),
                  trailing: const Icon(Icons.equalizer),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: ListTile(
                  title: const Text("Last.fm Login"),
                  subtitle: const Text("Connect your Last.fm account"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LastFmAuthScreen())),
                  trailing: const Icon(Icons.login),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: ListTile(
                  title: const Text("Force Sync Last.fm"),
                  subtitle: const Text("Manually push offline scrobbles to your account"),
                  // Pushes all cached offline scrobbles to the user's Last.fm profile
                  onTap: _isSyncingLastFm ? null : () async {
                    setState(() => _isSyncingLastFm = true);
                    try {
                      await ref.read(syncManagerProvider).forceSync();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline sync cycle completed.'), backgroundColor: Colors.green));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Failed: $e'), backgroundColor: Colors.red));
                    } finally {
                      if (mounted) setState(() => _isSyncingLastFm = false);
                    }
                  },
                  trailing: _isSyncingLastFm
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync, color: Colors.green),
                ),
              ),
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }
}