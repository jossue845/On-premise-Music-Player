import 'package:flutter/material.dart';
import 'package:music_player_app/presentation/screens/player_screen.dart'; 
import 'package:music_player_app/presentation/screens/sartist_screen.dart';
import 'package:music_player_app/presentation/screens/salbum_screen.dart';
import 'package:music_player_app/presentation/screens/lyrics_screen.dart';


class PlaylistDetailScreen extends StatefulWidget {
  final String playlistTitle;
  final bool initialIsPinned; 

  const PlaylistDetailScreen({
    super.key,
    required this.playlistTitle,
    required this.initialIsPinned, 
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late bool _isPinned; 

  // Our mock list of songs
  final List<Map<String, String>> _mockSongs = [
    {'title': 'Blinding Lights', 'artist': 'The Weeknd'},
    {'title': 'Levitating', 'artist': 'Dua Lipa'},
  ];

  @override
  void initState() {
    super.initState();
    _isPinned = widget.initialIsPinned; 
  }

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
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              
              Expanded(
                child: ListView.builder(
                  itemCount: _mockSongs.length,
                  itemBuilder: (context, index) {
                    final song = _mockSongs[index];
                    
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
                            // Pulls the placeholder background from the global theme
                            color: Theme.of(context).colorScheme.surfaceContainerHighest, 
                            child: Icon(
                              Icons.music_note,
                              // Automatically dims the global icon color for the placeholder
                              color: Theme.of(context).iconTheme.color?.withOpacity(0.5), 
                              size: 28,
                            ),
                          ),
                        ),
                        
                        // --- 2. Song Name and Artist ---
                        title: Text(
                          song['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(song['artist']!),
                        ),
                        
                        // --- 3. Options Menu (Three dots) ---
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (String choice) {
                            if (choice == 'remove') {
                              setState(() {
                                _mockSongs.removeAt(index);
                              });
                            } else if (choice == 'artist') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ArtistDetailScreen(artistName: song['artist']!)),
                              );
                            } else if (choice == 'album') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AlbumDetailScreen(albumName: '${song['title']} - Album')),
                              );
                            } else if (choice == 'lyrics') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LyricsScreen(songTitle: song['title']!)),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'remove',
                              child: Row(
                                children: [
                                  // Pulls the official "Error" color from the theme
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
                                  // No color defined! It inherits white from the theme automatically.
                                  Icon(Icons.person_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text('Go to artist'),
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
                        
                        // --- 4. Tap to Play ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PlayerScreen(),
                            ),
                          );
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