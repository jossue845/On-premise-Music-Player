import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';

class ManagePlaylistSongsScreen extends StatefulWidget {
  final String playlistTitle;
  final int? playlistId;
  final bool isFavoritesPlaylist;
  
  // Fix: Added dependencies for testing isolated widgets
  final DatabaseService? testDatabaseService;
  final SongRepository? testSongRepository;
  final PlaylistRepository? testPlaylistRepository;

  const ManagePlaylistSongsScreen({
    super.key,
    required this.playlistTitle,
    this.playlistId,
    this.isFavoritesPlaylist = false,
    this.testDatabaseService,
    this.testSongRepository,
    this.testPlaylistRepository,
  });

  @override
  State<ManagePlaylistSongsScreen> createState() => _ManagePlaylistSongsScreenState();
}

class _ManagePlaylistSongsScreenState extends State<ManagePlaylistSongsScreen> {
  late DatabaseService _databaseService;
  late SongRepository _songRepository;
  late PlaylistRepository _playlistRepository;

  List<Song> _allSongs = [];
  Set<int> _initialSelectedIds = {};
  Set<int> _currentSelectedIds = {};
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Refreshes and loads all available songs to display in the management list
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Fix: Use injected dependencies if available to prevent multiple database connections
    _databaseService = widget.testDatabaseService ?? DatabaseService(databaseFactory: databaseFactory);
    _songRepository = widget.testSongRepository ?? SongRepository(database: _databaseService);
    _playlistRepository = widget.testPlaylistRepository ?? PlaylistRepository(database: _databaseService);

    try {
      final allSongsResult = await _songRepository.getSongs();
      if (allSongsResult.isSuccess() == true) {
        _allSongs = allSongsResult.getOrThrow();
      }

      List<Song> playlistSongs = [];
      
      if (widget.isFavoritesPlaylist == true) {
        for (int i = 0; i < _allSongs.length; i++) {
          if (_allSongs[i].favorite == true) {
            playlistSongs.add(_allSongs[i]);
          }
        }
      } else {
        if (widget.playlistId != null) {
          final playlistSongsResult = await _songRepository.getSongs(playlistId: widget.playlistId);
          if (playlistSongsResult.isSuccess() == true) {
            playlistSongs = playlistSongsResult.getOrThrow();
          }
        }
      }

      _initialSelectedIds = {};
      for (int j = 0; j < playlistSongs.length; j++) {
        _initialSelectedIds.add(playlistSongs[j].id);
      }
      
      _currentSelectedIds = Set.from(_initialSelectedIds);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading songs for management: " + e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Computes set differences and executes batch database updates
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      final songsToAdd = _currentSelectedIds.difference(_initialSelectedIds).toList();
      final songsToRemove = _initialSelectedIds.difference(_currentSelectedIds).toList();

      if (widget.isFavoritesPlaylist) {
        await Future.wait([
          ...songsToAdd.map((id) => _databaseService.setFavoriteStatus(id, true)),
          ...songsToRemove.map((id) => _databaseService.setFavoriteStatus(id, false))
        ]);
      } else if (widget.playlistId != null) {
        if (songsToAdd.isNotEmpty) await _playlistRepository.addSongsToPlaylist(widget.playlistId!, songsToAdd);
        if (songsToRemove.isNotEmpty) await _playlistRepository.removeSongsFromPlaylist(widget.playlistId!, songsToRemove);
      }

      if (mounted) Navigator.pop(context, true); 
    } catch (e) {
      debugPrint("Error saving playlist changes: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage: ${widget.playlistTitle}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          _isSaving 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Save Changes',
                onPressed: _saveChanges,
              ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _allSongs.isEmpty
                  ? const Center(child: Text('Your library is empty!'))
                  : ListView.builder(
                      itemCount: _allSongs.length,
                      itemBuilder: (context, index) {
                        final song = _allSongs[index];
                        final isSelected = _currentSelectedIds.contains(song.id);

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _currentSelectedIds.add(song.id);
                              } else {
                                _currentSelectedIds.remove(song.id);
                              }
                            });
                          },
                          secondary: ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: Container(
                              width: 45,
                              height: 45,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: song.imagePath != null
                                  ? Image.file(File(song.imagePath!), fit: BoxFit.cover)
                                  : Icon(Icons.music_note, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
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
                        );
                      },
                    ),
        ),
      ),
    );
  }
}