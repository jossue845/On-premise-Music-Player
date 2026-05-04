import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// Screens 
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
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
  final bool isFavoritesPlaylist; // --- NEW FIELD ---

  const PlaylistDetailScreen({
    super.key,
    required this.playlistTitle,
    required this.initialIsPinned,
    this.playlistId, 
    this.isFavoritesPlaylist = false, // Defaults to false for normal playlists
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late bool _isPinned; 
  late SongRepository _songRepository;
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
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);
    
    try {
      // If this is the special Favorites playlist, fetch and filter!
      if (widget.isFavoritesPlaylist) {
        final result = await _songRepository.getSongs();
        if (result.isSuccess()) {
          setState(() {
            _songs = result.getOrThrow().where((song) => song.favorite).toList();
            _isLoading = false;
          });
        }
      } 
      // Otherwise, load a standard playlist from the DB
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

  // ... (Keep your exact same @override Widget build(BuildContext context) method here!)

  @override
  Widget build(BuildContext context) {
    // PopScope ensures we always return the pin state when swiping back or hitting the system back button
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
            onPressed: () {
              Navigator.pop(context, _isPinned); 
            },
          ),
          title: Text(widget.playlistTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              color: _isPinned ? Theme.of(context).primaryColor : Colors.white,
              tooltip: 'Pin Playlist',
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                });
              },
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
                              
                              // --- 1. The Song Image ---
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
                              
                              // --- 2. Song Name and Artist ---
                              title: Text(
                                song.title, // Updated to use Song model property
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
                              
                              // --- 3. Options Menu 
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (String choice) async {
                                  if (choice == 'remove') {
                                    // TODO: Actually delete from DB if using DB
                                    setState(() {
                                      _songs.removeAt(index);
                                    });
                                  } else if (choice == 'artist') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ArtistDetailScreen(
                                        artistName: song.artists.isNotEmpty ? song.artists.first : 'Unknown Artist'
                                      )),
                                    );
                                  } else if (choice == 'album') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AlbumDetailScreen(
                                        albumName: song.album
                                      )),
                                    );
                                  } else if (choice == 'lyrics') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => LyricsScreen(
                                        songTitle: song.title
                                      )),
                                    );
                                  }
                                  else if (choice == 'edit') {
                                    // Navigate to the Edit Song Screen
                                    final didUpdate = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => EditSongScreen(song: song)),
                                    );
                                    
                                    // If the song was edited, refresh the playlist
                                    if (didUpdate == true) {
                                      _loadPlaylistSongs();
                                    }
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                                        const SizedBox(width: 12),
                                        Text('Remove from playlist', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'artist',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 20),
                                        SizedBox(width: 12),
                                        Text('Go to artist'),
                                      ],
                                    ),
                                  ),

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

                                  const PopupMenuItem<String>(
                                    value: 'album',
                                    child: Row(
                                      children: [
                                        Icon(Icons.album_outlined, size: 20),
                                        SizedBox(width: 12),
                                        Text('Go to album'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'lyrics',
                                    child: Row(
                                      children: [
                                        Icon(Icons.lyrics_outlined, size: 20),
                                        SizedBox(width: 12),
                                        Text('Show lyrics'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // --- 4. Tap to Play (FIXED) ---
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(
                                      playlist: _songs, // Pass the whole list!
                                      initialIndex: index, // Pass the index!
                                    ),
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
