import 'package:flutter/material.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final List<Map<String, dynamic>> _mockPlaylists = [];
  final TextEditingController _playlistNameController = TextEditingController();
  
  // Tracking which playlists are currently selected
  final Set<int> _selectedIndices = {};

  // --- SELECTION LOGIC ---
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
      // Sort descending to remove from the bottom up, preventing index shifting errors
      final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final index in sortedIndices) {
        _mockPlaylists.removeAt(index);
      }
      _selectedIndices.clear();
    });
  }

  void _pinSelected() {
    setState(() {
      for (final index in _selectedIndices) {
        _mockPlaylists[index]['isPinned'] = !(_mockPlaylists[index]['isPinned'] as bool);
      }
      
      // Sort the list so pinned items automatically jump to the top
      _mockPlaylists.sort((a, b) {
        if (a['isPinned'] == b['isPinned']) return 0;
        return a['isPinned'] ? -1 : 1;
      });
      
      _selectedIndices.clear();
    });
  }

  // --- POPUP LOGIC ---
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
                      'isPinned': false, // Add the pin status to new playlists!
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
      // 3. The Contextual AppBar swaps automatically
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
                  icon: const Icon(Icons.push_pin),
                  tooltip: 'Pin/Unpin',
                  onPressed: _pinSelected,
                ),
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
            final bool isPinned = playlist['isPinned'] as bool;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              // Highlights the card in cyan if it is selected
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                // Adds a glowing border to selected items
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
                    // Shows a small pin icon next to the title if pinned
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
                // 4. Interaction routing
                onLongPress: () => _toggleSelection(index),
                onTap: () {
                  if (isSelectionMode) {
                    _toggleSelection(index);
                  } else {
                    // Normal navigation to playlist details goes here
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