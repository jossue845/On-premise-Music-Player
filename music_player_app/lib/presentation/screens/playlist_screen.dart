import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// Other screens
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart';
import 'package:music_player_app/presentation/screens/playlistdetail_screen.dart';
import 'package:music_player_app/presentation/screens/manage_playlist_songs_screen.dart'; 

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late SongRepository _songRepository;
  late PlaylistRepository _playlistRepository;
  
  int _favoritesCount = 0;
  List<dynamic> _customPlaylists = []; 
  bool _isLoading = true;

  final TextEditingController _playlistNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);
    _playlistRepository = PlaylistRepository(database: databaseService);

    try {
      final songResult = await _songRepository.getSongs();
      if (songResult.isSuccess()) {
        final allSongs = songResult.getOrThrow();
        _favoritesCount = allSongs.where((song) => song.favorite).length;
      }

      final playlistResult = await _playlistRepository.getPlaylists();
      if (playlistResult.isSuccess()) {
        _customPlaylists = playlistResult.getOrThrow();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error loading playlists: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: _playlistNameController,
            decoration: const InputDecoration(
              hintText: 'Enter playlist name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _playlistNameController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final title = _playlistNameController.text.trim();
                if (title.isNotEmpty) {
                  await _playlistRepository.createPlaylist(title);
                  _playlistNameController.clear();
                  Navigator.pop(context);
                  _loadData(); 
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _deletePlaylist(int playlistId) async {
    await _playlistRepository.deletePlaylists([playlistId]);
    _loadData(); 
  }

  // --- NEW: Universal Navigation to Manage Screen ---
  void _navigateToManageSongs({required String title, int? id, bool isFavorites = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagePlaylistSongsScreen(
          playlistTitle: title,
          playlistId: id,
          isFavoritesPlaylist: isFavorites,
        ),
      ),
    ).then((changesMade) {
      // If the user hit save on the manage screen, refresh the playlist counts!
      if (changesMade == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        tooltip: 'Create Playlist',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- 1. DEFAULT FAVORITES PLAYLIST ---
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.red),
                    ),
                    title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$_favoritesCount songs'),
                    
                    // Added PopupMenu for Favorites
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'manage') {
                          _navigateToManageSongs(title: 'Favorites', isFavorites: true);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'manage',
                          child: Row(
                            children: [
                              Icon(Icons.checklist, size: 20),
                              SizedBox(width: 12),
                              Text('Add / Remove songs'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlaylistDetailScreen(
                            playlistTitle: 'Favorites',
                            initialIsPinned: true,
                            isFavoritesPlaylist: true, 
                          ),
                        ),
                      ).then((_) => _loadData()); 
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // --- CUSTOM PLAYLISTS ---
                if (_customPlaylists.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'My Playlists', 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                    ),
                  ),
                  ..._customPlaylists.map((playlist) {
                    final playlistTitle = playlist.title; 
                    final playlistId = playlist.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.queue_music, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(playlistTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        
                        // Updated to include Manage Songs
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'manage') {
                              _navigateToManageSongs(title: playlistTitle, id: playlistId);
                            } else if (value == 'delete') {
                              _deletePlaylist(playlistId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'manage',
                              child: Row(
                                children: [
                                  Icon(Icons.checklist, size: 20),
                                  SizedBox(width: 12),
                                  Text('Add / Remove songs'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                                  const SizedBox(width: 12),
                                  Text('Delete playlist', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistDetailScreen(
                                playlistTitle: playlistTitle,
                                playlistId: playlistId, 
                                initialIsPinned: false,
                              ),
                            ),
                          ).then((_) => _loadData()); 
                        },
                      ),
                    );
                  }),
                ]
              ],
            ),
    );
  }
}