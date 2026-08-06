import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// Screens 
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart'; // Needed for adding/removing
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart'; 
import 'package:music_player_app/presentation/screens/sartist_screen.dart';
import 'package:music_player_app/presentation/screens/salbum_screen.dart';
import 'package:music_player_app/presentation/screens/lyrics_screen.dart';
import 'package:music_player_app/presentation/screens/edit_song_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistTitle;
  final bool initialIsPinned; 
  final int? playlistId; 
  final bool isFavoritesPlaylist; 

  const PlaylistDetailScreen({
    super.key,
    required this.playlistTitle,
    required this.initialIsPinned,
    this.playlistId, 
    this.isFavoritesPlaylist = false, 
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late bool _isPinned; 
  late SongRepository _songRepository;
  late PlaylistRepository _playlistRepository; // Added repository
  late DatabaseService _databaseService; // Kept reference to toggle favorites
  
  List<Song> _songs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isPinned = widget.initialIsPinned; 
    _loadPlaylistSongs();
  }

  Future<void> _loadPlaylistSongs() async {
    setState(() => _isLoading = true);
    _databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: _databaseService);
    _playlistRepository = PlaylistRepository(database: _databaseService); // Initialize
    
    try {
      if (widget.isFavoritesPlaylist) {
        final result = await _songRepository.getSongs();
        if (result.isSuccess()) {
          setState(() {
            _songs = result.getOrThrow().where((song) => song.favorite).toList();
            _isLoading = false;
          });
        }
      } 
      else if (widget.playlistId != null) {
        final result = await _songRepository.getSongs(playlistId: widget.playlistId);
        if (result.isSuccess()) {
          setState(() {
            _songs = result.getOrThrow();
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- NEW: Add to Playlist Dialog ---
  Future<void> _showAddToPlaylistDialog(Song song) async {
    final result = await _playlistRepository.getPlaylists();
    if (result.isSuccess()) {
      final playlists = result.getOrThrow();
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add to Playlist'),
            content: SizedBox(
              width: double.maxFinite,
              child: playlists.isEmpty 
                ? const Text('No custom playlists available. Create one first!')
                : ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final pl = playlists[index];
                  return ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(pl.title),
                    onTap: () async {
                      await _playlistRepository.addSongsToPlaylist(pl.id, [song.id]);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${pl.title}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ],
          );
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _isPinned);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _isPinned),
          ),
          title: Text(widget.playlistTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              color: _isPinned ? Theme.of(context).primaryColor : Colors.white,
              tooltip: 'Pin Playlist',
              onPressed: () => setState(() => _isPinned = !_isPinned),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Expanded(
                      child: _songs.isEmpty 
                        ? const Center(child: Text("No songs in this playlist yet."))
                        : ListView.builder(
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8.0),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Container(
                                  width: 55,
                                  height: 55,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest, 
                                  child: song.imagePath != null
                                      ? Image.file(File(song.imagePath!), fit: BoxFit.cover)
                                      : Icon(
                                          Icons.music_note,
                                          color: Theme.of(context).iconTheme.color?.withOpacity(0.5), 
                                          size: 28,
                                        ),
                                ),
                              ),
                              title: Text(
                                song.title, 
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  song.artists.isNotEmpty ? song.artists.first : 'Unknown Artist',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              // --- 3. Updated Options Menu ---
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (String choice) async {
                                  if (choice == 'toggle_favorite') {
                                    // Bypassed Repository and went straight to DB Service to ensure it executes
                                    await _databaseService.setFavoriteStatus(song.id, !song.favorite);
                                    _loadPlaylistSongs();
                                  } 
                                  else if (choice == 'add_to_playlist') {
                                    _showAddToPlaylistDialog(song);
                                  } 
                                  else if (choice == 'remove') {
                                    if (widget.isFavoritesPlaylist) {
                                      await _databaseService.setFavoriteStatus(song.id, false);
                                    } else if (widget.playlistId != null) {
                                      await _playlistRepository.removeSongsFromPlaylist(widget.playlistId!, [song.id]);
                                    }
                                    _loadPlaylistSongs();
                                  } 
                                  else if (choice == 'artist') {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistDetailScreen(artistName: song.artists.isNotEmpty ? song.artists.first : 'Unknown Artist')));
                                  } else if (choice == 'album') {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => AlbumDetailScreen(albumName: song.album)));
                                  } else if (choice == 'lyrics') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LyricsScreen(
                                          song: song,
                                          songRepository: _songRepository,
                                        ),
                                      ),
                                    );
                                  } else if (choice == 'edit') {
                                    final didUpdate = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditSongScreen(song: song)));
                                    if (didUpdate == true) _loadPlaylistSongs();
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  
                                  // 1. Dynamic Favorite Button
                                  PopupMenuItem<String>(
                                    value: 'toggle_favorite',
                                    child: Row(
                                      children: [
                                        Icon(song.favorite ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 20),
                                        const SizedBox(width: 12),
                                        Text(song.favorite ? 'Remove from Favorites' : 'Add to Favorites'),
                                      ],
                                    ),
                                  ),

                                  // 2. Add to Custom Playlist
                                  const PopupMenuItem<String>(
                                    value: 'add_to_playlist',
                                    child: Row(
                                      children: [
                                        Icon(Icons.playlist_add, size: 20),
                                        SizedBox(width: 12),
                                        Text('Add to Playlist...'),
                                      ],
                                    ),
                                  ),

                                  // 3. Remove Button (Only shows if we are currently inside a playlist)
                                  if (widget.playlistId != null || widget.isFavoritesPlaylist)
                                    PopupMenuItem<String>(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                                          const SizedBox(width: 12),
                                          Text('Remove from this playlist', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                        ],
                                      ),
                                    ),
                                    
                                  const PopupMenuDivider(),

                                  const PopupMenuItem<String>(
                                    value: 'artist',
                                    child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 12), Text('Go to artist')]),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'album',
                                    child: Row(children: [Icon(Icons.album_outlined, size: 20), SizedBox(width: 12), Text('Go to album')]),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit song info')]),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'lyrics',
                                    child: Row(children: [Icon(Icons.lyrics_outlined, size: 20), SizedBox(width: 12), Text('Show lyrics')]),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(playlist: _songs, initialIndex: index),
                                  ),
                                ).then((_) => _loadPlaylistSongs());
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}