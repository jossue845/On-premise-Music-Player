import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/data/services/audiodb_service.dart'; 

class EditSongScreen extends StatefulWidget {
  final Song song;
  // Fix: Add injected dependencies for testing
  final SongRepository? testSongRepository;
  final AudioDbService? testAudioDbService;

  const EditSongScreen({
    super.key, 
    required this.song, 
    this.testSongRepository,
    this.testAudioDbService,
  });

  @override
  State<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends State<EditSongScreen> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;
  late TextEditingController _yearController;
  late TextEditingController _trackNumberController;

  late SongRepository _songRepository;
  bool _isLoading = false;
  bool _isSearching = false;
  late Song _currentSong;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _titleController = TextEditingController(text: _currentSong.title);
    
    String artistText = '';
    if (_currentSong.artists.isNotEmpty == true) {
      artistText = _currentSong.artists.join('; ');
    }
    _artistController = TextEditingController(text: artistText);
    
    _albumController = TextEditingController(text: _currentSong.album);
    _genreController = TextEditingController(text: _currentSong.genre ?? '');
    _yearController = TextEditingController(text: _currentSong.year?.toString() ?? '');
    _trackNumberController = TextEditingController(text: _currentSong.trackNumber?.toString() ?? '');

    // Fix: Use injected repository if available
    if (widget.testSongRepository != null) {
      _songRepository = widget.testSongRepository!;
    } else {
      final databaseService = DatabaseService(databaseFactory: databaseFactory);
      _songRepository = SongRepository(database: databaseService);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _trackNumberController.dispose();
    super.dispose();
  }

  // Fetches metadata from TheAudioDB and auto-fills the text fields
  Future<void> _autoFixMetadata() async {
    setState(() => _isSearching = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Searching TheAudioDB for metadata...')),
    );

    final adbService = widget.testAudioDbService ?? AudioDbService();
    final artistName = _artistController.text.isNotEmpty ? _artistController.text : 'Unknown Artist';
    
    final searchResult = await adbService.searchTrack(_titleController.text, artistName);

    if (!mounted) return;
    setState(() => _isSearching = false);

    // Fix: Instantly hide the "Searching..." SnackBar so the result can show
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (searchResult.isSuccess() == true) {
      final data = searchResult.getOrThrow();
      final tracks = data['track'] as List?;

      if (tracks != null && tracks.isNotEmpty) {
        final match = tracks.first;
        
        setState(() {
          _titleController.text = match['strTrack'] as String? ?? _titleController.text;
          _artistController.text = match['strArtist'] as String? ?? _artistController.text;
          _albumController.text = match['strAlbum'] as String? ?? _albumController.text;
          _genreController.text = match['strGenre'] as String? ?? _genreController.text;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fields auto-filled! Please review and tap Save.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No matching track found on TheAudioDB.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${searchResult.exceptionOrNull()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Parses user input and saves the updated ID3 tags to the file and database
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    List<String> rawArtists = _artistController.text.split(';');
    List<String> newArtists = [];
    
    for (int i = 0; i < rawArtists.length; i++) {
      String trimmed = rawArtists[i].trim();
      if (trimmed != '') {
        newArtists.add(trimmed);
      }
    }

    final result = await _songRepository.editTags(
      oldSong: _currentSong,
      newTitle: _titleController.text.trim(),
      newSongArtistNames: newArtists,
      newAlbumArtistNames: newArtists,
      newAlbumTitle: _albumController.text.trim(),
      newGenre: _genreController.text.trim().isNotEmpty ? _genreController.text.trim() : null,
      newYear: int.tryParse(_yearController.text.trim()),
      newTrackNumber: int.tryParse(_trackNumberController.text.trim()),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.isSuccess() == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${result.exceptionOrNull()}'),
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
        title: const Text('Edit Song Info'),
        bottom: _isSearching
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: Colors.orangeAccent),
            tooltip: 'Auto-Fix with TheAudioDB',
            onPressed: _isLoading || _isSearching ? null : _autoFixMetadata,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _isLoading || _isSearching ? null : _saveChanges,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _artistController,
                        decoration: const InputDecoration(labelText: 'Artists (semicolon-separated)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _albumController,
                        decoration: const InputDecoration(labelText: 'Album'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _genreController,
                        decoration: const InputDecoration(labelText: 'Genre'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Year'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _trackNumberController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Track #'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}