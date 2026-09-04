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
  // --- FIX: Added dependencies for headless testing ---
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
    // --- FIX: Use injected dependencies if available ---
    _databaseService = widget.testDatabaseService ?? DatabaseService(databaseFactory: databaseFactory);
    _filesystemService = widget.testFilesystemService ?? FilesystemService();
    _musicFolderRepository = widget.testMusicFolderRepository ?? MusicFolderRepository(
      database: _databaseService,
      fs: _filesystemService,
    );
    _loadTiltSetting();
  }

  Future _loadTiltSetting() async {
    final res = await _databaseService.getValue('tilt_enabled');
    if (res.isSuccess() && mounted) {
      setState(() => _tiltEnabled = res.getOrThrow() == 'true');
    }
  }

  Future _scanMusic() async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Music scan completed!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = result.exceptionOrNull();
        setState(() {
          _isScanning = false;
          _scanStatus = 'Error: ${error?.toString() ?? 'Unknown error'}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scan failed: ${error?.toString() ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanStatus = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future _setSongsFolder() async {
    try {
      final result = await _musicFolderRepository.setMusicFolder();
      
      if (result.isSuccess()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Music folder set successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = result.exceptionOrNull();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error?.toString() ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future _scanForMissingArtwork() async {
    setState(() => _isFetchingArt = true);
    
    // --- FIX: Use injected repository ---
    final songRepo = widget.testSongRepository ?? SongRepository(database: _databaseService);
    
    try {
      final result = await songRepo.getSongs();
      if (result.isSuccess()) {
        final songs = result.getOrThrow();
        
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

  Future _batchValidateTags() async {
    setState(() {
      _isBatchValidating = true;
      _validationProgress = 'Starting validation...';
    });

    // --- FIX: Use injected repository ---
    final songRepo = widget.testSongRepository ?? SongRepository(database: _databaseService);

    final updatedCount = await songRepo.validateAndFixAllSongs(
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _validationProgress = 'Validating $current of $total songs...';
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isBatchValidating = false;
        _validationProgress = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch validation complete! Updated $updatedCount tracks.'),
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
                  onChanged: (val) async {
                    setState(() => _tiltEnabled = val);
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
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : const Icon(Icons.auto_fix_high, color: Colors.orangeAccent),
                ),
              ),
                          
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: ListTile(
                  title: const Text("Equalizer"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EqualizerScreen(
                          // --- FIX: Pass the injected database down the navigation stack ---
                          testDatabaseService: widget.testDatabaseService,
                        ),
                      ),
                    ); 
                  },
                  trailing: const Icon(Icons.equalizer),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: ListTile(
                  title: const Text("Last.fm Login"),
                  subtitle: const Text("Connect your Last.fm account"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LastFmAuthScreen(),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.login),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: ListTile(
                  title: const Text("Force Sync Last.fm"),
                  subtitle: const Text("Manually push offline scrobbles to your account"),
                  onTap: _isSyncingLastFm ? null : () async {
                    setState(() => _isSyncingLastFm = true);

                    try {
                      await ref.read(syncManagerProvider).forceSync();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offline sync cycle completed.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sync Failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSyncingLastFm = false);
                    }
                  },
                  trailing: _isSyncingLastFm
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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