import 'package:flutter/material.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart'; // Make sure you import this!
import 'package:music_player_app/presentation/screens/playlistdetail_screen.dart';
import 'package:sqflite/sqflite.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late SongRepository _songRepository;
  late PlaylistRepository _playlistRepository;
  
  int _favoritesCount = 0;
  List<dynamic> _customPlaylists = []; // Holds your user-created playlists
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
      // 1. Load songs to count favorites
      final songResult = await _songRepository.getSongs();
      if (songResult.isSuccess()) {
        final allSongs = songResult.getOrThrow();
        _favoritesCount = allSongs.where((song) => song.favorite).length;
      }

      // 2. Load the custom playlists from the database
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

  // --- NEW: Create Playlist Dialog ---
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
                  // Save to database
                  await _playlistRepository.createPlaylist(title);
                  _playlistNameController.clear();
                  Navigator.pop(context);
                  _loadData(); // Refresh the screen
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // --- NEW: Delete Playlist ---
  void _deletePlaylist(int playlistId) async {
    await _playlistRepository.deletePlaylists([playlistId]);
    _loadData(); // Refresh the screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      // --- NEW: The FAB ---
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
                // --- 1. DEFAULT FAVORITES PLAYLIST (Permanent, no delete button) ---
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
                
                // --- 2. CUSTOM PLAYLISTS ---
                if (_customPlaylists.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'My Playlists', 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                    ),
                  ),
                  ..._customPlaylists.map((playlist) {
                    // Note: Depending on how the Playlist model was named by your colleague, 
                    // this might need to be playlist.name instead of playlist.title
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
                        
                        // Adding the delete option ONLY to custom playlists
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') _deletePlaylist(playlistId);
                          },
                          itemBuilder: (context) => [
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
                                playlistId: playlistId, // Pass the ID so the detail screen fetches its songs
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