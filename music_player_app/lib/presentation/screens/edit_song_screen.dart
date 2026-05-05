import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:sqflite/sqflite.dart';

class EditSongScreen extends StatefulWidget {
  final Song song;

  const EditSongScreen({super.key, required this.song});

  @override
  State<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends State<EditSongScreen> {
  // Controllers to hold and edit the text
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;

  late SongRepository _songRepository;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // 1. Pre-fill the controllers with the current song's data
    _titleController = TextEditingController(text: widget.song.title);
    _albumController = TextEditingController(text: widget.song.album);
    
    // Since artists is a List<String>, we join them with a comma for editing
    final String currentArtists = widget.song.artists.isNotEmpty 
        ? widget.song.artists.join(', ') 
        : '';
    _artistController = TextEditingController(text: currentArtists);

    // 2. Setup the database connection for when we hit save
    final databaseService = DatabaseService(databaseFactory: databaseFactory);
    _songRepository = SongRepository(database: databaseService);
  }

  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks!
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final updatedTitle = _titleController.text.trim();
    final updatedAlbum = _albumController.text.trim();
    
    // Split the comma-separated artist string back into a List<String>
    final updatedArtists = _artistController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // --- THE REAL DATABASE & TAG WRITER CALL ---
    final result = await _songRepository.editTags(
      oldSong: widget.song,
      newTitle: updatedTitle.isNotEmpty ? updatedTitle : null,
      newSongArtistNames: updatedArtists.isNotEmpty ? updatedArtists : null,
      newAlbumTitle: updatedAlbum.isNotEmpty ? updatedAlbum : null,
      // newAlbumArtistNames: updatedArtists.isNotEmpty ? updatedArtists : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      
      // Check if the database update was actually successful
      if (result.isSuccess()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song metadata updated!')),
        );
        // Pop the screen and return 'true' to trigger the refresh on the previous screen
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${result.exceptionOrNull()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Song Info', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // The Save Button
          _isSaving 
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            : IconButton(
                icon: const Icon(Icons.check),
                color: Theme.of(context).primaryColor,
                onPressed: _saveChanges,
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Show the Album Art for context ---
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 180,
                  width: 180,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: widget.song.imagePath != null
                      ? Image.file(File(widget.song.imagePath!), fit: BoxFit.cover)
                      : Icon(
                          Icons.music_note, 
                          size: 80, 
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.5)
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // --- 2. The Input Fields ---
            _buildTextField(
              controller: _titleController,
              label: 'Song Title',
              icon: Icons.title,
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _artistController,
              label: 'Artist(s)',
              hint: 'Separate multiple artists with commas',
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _albumController,
              label: 'Album',
              icon: Icons.album,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
    );
  }
}