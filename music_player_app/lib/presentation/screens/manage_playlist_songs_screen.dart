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

  const ManagePlaylistSongsScreen({
    super.key,
    required this.playlistTitle,
    this.playlistId,
    this.isFavoritesPlaylist = false,
  });

  @override
  State<ManagePlaylistSongsScreen> createState() => _ManagePlaylistSongsScreenState();
}

class _ManagePlaylistSongsScreenState extends State<ManagePlaylistSongsScreen> {
  late DatabaseService _databaseService;
  late SongRepository _songRepository;
  late PlaylistRepository _playlistRepository;

  List<Song> _allSongs = [];
  
  // We use Sets for super-fast lookups and comparisons
  Set<int> _initialSelectedIds = {};
  Set<int> _currentSelectedIds = {};
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: _databaseService);
    _playlistRepository = PlaylistRepository(database: _databaseService);

    try {
      // 1. Fetch ALL songs in the library
      final allSongsResult = await _songRepository.getSongs();
      if (allSongsResult.isSuccess()) {
        _allSongs = allSongsResult.getOrThrow();
      }

      // 2. Fetch songs specifically in THIS playlist to pre-tick them
      List<Song> playlistSongs = [];
      if (widget.isFavoritesPlaylist) {
        playlistSongs = _allSongs.where((song) => song.favorite).toList();
      } else if (widget.playlistId != null) {
        final playlistSongsResult = await _songRepository.getSongs(playlistId: widget.playlistId);
        if (playlistSongsResult.isSuccess()) {
          playlistSongs = playlistSongsResult.getOrThrow();
        }
      }

      // 3. Map the playlist songs to a Set of IDs
      _initialSelectedIds = playlistSongs.map((s) => s.id).toSet();
      _currentSelectedIds = Set.from(_initialSelectedIds); // Clone for active editing

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error loading songs for management: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      // Figure out what needs to be added and what needs to be removed
      final songsToAdd = _currentSelectedIds.difference(_initialSelectedIds).toList();
      final songsToRemove = _initialSelectedIds.difference(_currentSelectedIds).toList();

      if (widget.isFavoritesPlaylist) {
        // Handle Favorites logic natively through the Database Service
        for (int id in songsToAdd) {
          await _databaseService.setFavoriteStatus(id, true);
        }
        for (int id in songsToRemove) {
          await _databaseService.setFavoriteStatus(id, false);
        }
      } else if (widget.playlistId != null) {
        // Handle Custom Playlist logic
        if (songsToAdd.isNotEmpty) {
          await _playlistRepository.addSongsToPlaylist(widget.playlistId!, songsToAdd);
        }
        if (songsToRemove.isNotEmpty) {
          await _playlistRepository.removeSongsFromPlaylist(widget.playlistId!, songsToRemove);
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Pop and signal that changes were made
      }
    } catch (e) {
      debugPrint("Error saving playlist changes: $e");
      setState(() => _isSaving = false);
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
      body: _isLoading
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
    );
  }
}