import 'package:flutter/material.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:music_player_app/domain/models/song/song.dart';

class LyricsScreen extends StatefulWidget {
  final Song song;
  final SongRepository songRepository;

  const LyricsScreen({super.key, required this.song, required this.songRepository});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  bool _isLoading = true;
  String _lyricsContent = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
  debugPrint('🟡 _loadLyrics() called for songId=${widget.song.id}, title=${widget.song.title}');
  if (widget.song.lyrics != null && widget.song.lyrics!.isNotEmpty) {
    setState(() {
      _lyricsContent = widget.song.lyrics!;
      _isLoading = false;
    });
    return;
  }

  final databaseService = DatabaseService(databaseFactory: databaseFactory);
  final songRepo = SongRepository(database: databaseService);

  try {
    final result = await songRepo.fetchAndSaveLyrics(widget.song);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess()) {
          _lyricsContent = result.getOrThrow();
        } else {
          _errorMessage = result.exceptionOrNull()?.toString() ?? 'Failed to load lyrics.';
        }
      });
    }
  } catch (e, st) {
    debugPrint('🔴 CAUGHT IN _loadLyrics: $e');
    debugPrint('🔴 STACK:\n$st');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Debug: $e';
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lyrics', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  widget.song.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red, fontSize: 16),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Text(
                                _lyricsContent,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, height: 1.8),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}