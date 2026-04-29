import 'package:flutter/material.dart';
import 'package:music_player_app/presentation/screens/playlistdetail_screen.dart'; // Adjust path if needed!

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final List<Map<String, dynamic>> _mockPlaylists = [ ];

  final TextEditingController _playlistNameController = TextEditingController();
  final Set<int> _selectedIndices = {};

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final index in sortedIndices) {
        _mockPlaylists.removeAt(index);
      }
      _selectedIndices.clear();
    });
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _playlistNameController,
            autofocus: true, 
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Enter playlist name...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _playlistNameController.clear(); 
                Navigator.pop(context); 
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_playlistNameController.text.isNotEmpty) {
                  setState(() {
                    _mockPlaylists.insert(0, {
                      'title': _playlistNameController.text,
                      'tracks': '0 songs', 
                      'isPinned': false,
                    });
                  });
                  _playlistNameController.clear(); 
                  Navigator.pop(context); 
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelectionMode = _selectedIndices.isNotEmpty;

    return Scaffold(
      appBar: isSelectionMode
          ? AppBar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedIndices.clear()),
              ),
              title: Text('${_selectedIndices.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: _deleteSelected,
                ),
              ],
            )
          : AppBar(
              title: const Text('Playlists', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            
      floatingActionButton: isSelectionMode ? null : FloatingActionButton.extended(
        onPressed: _showCreatePlaylistDialog,
        backgroundColor: Theme.of(context).primaryColor, 
        foregroundColor: Colors.black, 
        icon: const Icon(Icons.add),
        label: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: _mockPlaylists.length,
          itemBuilder: (context, index) {
            final playlist = _mockPlaylists[index];
            final bool isSelected = _selectedIndices.contains(index);
            final bool isPinned = playlist['isPinned'] ?? false;
          
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected 
                  ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
                  : BorderSide.none,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(8.0),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFF2A2A2A), 
                    child: Icon(
                      Icons.queue_music,
                      color: Theme.of(context).primaryColor, 
                      size: 30,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        playlist['title'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isPinned)
                      Icon(Icons.push_pin, size: 16, color: Theme.of(context).primaryColor),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(playlist['tracks'].toString()),
                ),
                trailing: isSelectionMode 
                  ? Checkbox(
                      value: isSelected,
                      activeColor: Theme.of(context).primaryColor,
                      checkColor: Colors.black,
                      onChanged: (_) => _toggleSelection(index),
                    )
                  : IconButton(
                      icon: const Icon(Icons.play_circle_fill, size: 36),
                      onPressed: () {},
                    ),
                onLongPress: () => _toggleSelection(index),
                onTap: () async {
                  if (isSelectionMode) {
                    _toggleSelection(index);
                  } else {
                    // WAIT the updated pin state from the detail screen
                    final updatedPinState = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(
                          playlistTitle: playlist['title'].toString(),
                          initialIsPinned: isPinned,
                        ),
                      ),
                    );

                    // If it returns data, update and re-sort
                    if (updatedPinState != null && updatedPinState != isPinned) {
                      setState(() {
                        _mockPlaylists[index]['isPinned'] = updatedPinState;
                        
                        _mockPlaylists.sort((a, b) {
                          if (a['isPinned'] == b['isPinned']) return 0;
                          return a['isPinned'] ? -1 : 1;
                        });
                      });
                    }
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}