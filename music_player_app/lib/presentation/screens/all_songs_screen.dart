import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sqflite/sqflite.dart';

import 'package:music_player_app/data/providers/audio_player_provider.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/edit_song_screen.dart';

// --- FIX: Converted to ConsumerStatefulWidget to access Riverpod ---
class AllSongsScreen extends ConsumerStatefulWidget {
  final SongRepository? songRepository;
  final PlaylistRepository? playlistRepository;

  const AllSongsScreen({
    super.key,
    this.songRepository,
    this.playlistRepository,
  });

  @override
  ConsumerState<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends ConsumerState<AllSongsScreen> {
  late SongRepository _songRepository;
  late PlaylistRepository _playlistRepository;
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeRepositoryAndLoad();
  }

  Future<void> _initializeRepositoryAndLoad() async {
    setState(() => _isLoading = true);

    if (widget.songRepository != null && widget.playlistRepository != null) {
      _songRepository = widget.songRepository!;
      _playlistRepository = widget.playlistRepository!;
    } else {
      final databaseService = DatabaseService(databaseFactory: databaseFactory);
      _songRepository = SongRepository(database: databaseService);
      _playlistRepository = PlaylistRepository(database: databaseService);
    }
    try {
      final result = await _songRepository.getSongs();
      if (result.isSuccess()) {
        final List<Song> fetchedSongs = List<Song>.from(result.getOrThrow());
        
        fetchedSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        
        debugPrint("🎵 DATABASE CHECK: Found ${fetchedSongs.length} songs!");
        
        setState(() {
          _songs = fetchedSongs;
          _isLoading = false;
        });
      } else {
        debugPrint("🎵 DATABASE ERROR: ${result.exceptionOrNull()}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("🎵 EXCEPTION CAUGHT: $e");
      setState(() => _isLoading = false);
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Songs', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No songs found.'),
                      TextButton(
                        onPressed: _initializeRepositoryAndLoad,
                        child: const Text('Tap here to refresh'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _initializeRepositoryAndLoad,
                  color: Theme.of(context).primaryColor,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 600) {
                        return GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          itemCount: _songs.length,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) => _buildSongCard(context, index),
                        );
                      } else {
                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _songs.length,
                          itemBuilder: (context, index) => _buildSongCard(context, index),
                        );
                      }
                    },
                  ),
                ),
    );
  }

  Widget _buildSongCard(BuildContext context, int index) {
    final song = _songs[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String choice) async {
            if (choice == 'edit') {
              final didUpdate = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditSongScreen(song: song)),
              );
              
              if (didUpdate == true) {
                _initializeRepositoryAndLoad(); 
              }
            } else if (choice == 'add_to_playlist') {
              _showAddToPlaylistDialog(song);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'add_to_playlist',
              child: Row(
                children: [
                  Icon(Icons.playlist_add, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add to Playlist...',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit song info',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            width: 50,
            height: 50,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: song.imagePath != null
                ? Image.file(File(song.imagePath!), fit: BoxFit.cover)
                : const Icon(Icons.music_note),
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
        onTap: () async {
          // --- FIX: Push directly to the background service instead of opening a route ---
          final audioPlayer = ref.read(audioPlayerProvider);
          final audioSources = _songs.map((s) => AudioSource.uri(
            Uri.file(s.path),
            tag: MediaItem(
              id: s.id.toString(),
              title: s.title,
              artist: s.artists.isNotEmpty ? s.artists.first : 'Unknown Artist',
              album: s.album,
              artUri: s.imagePath != null ? Uri.file(s.imagePath!) : null,
            ),
          )).toList();
          
          await audioPlayer.setAudioSource(
            ConcatenatingAudioSource(children: audioSources), 
            initialIndex: index
          );
          await audioPlayer.play();
        },
      ),
    );
  }
}