import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

// Services
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/domain/models/artist/artist.dart';
import 'package:music_player_app/domain/models/album/album.dart';
import 'package:music_player_app/domain/models/playlist/playlist.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart';

// Screens
import 'package:music_player_app/presentation/screens/player_screen.dart';
import 'package:music_player_app/presentation/screens/sartist_screen.dart';
import 'package:music_player_app/presentation/screens/salbum_screen.dart'; 
import 'package:music_player_app/presentation/screens/playlistdetail_screen.dart'; 

class SearchScreen extends StatefulWidget {
  // --- FIX: Expand dependencies to pass down to child screens ---
  final DatabaseService? testDatabaseService;
  final SongRepository? testSongRepository;
  final PlaylistRepository? testPlaylistRepository;

  const SearchScreen({
    super.key,
    this.testDatabaseService,
    this.testSongRepository,
    this.testPlaylistRepository,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "All"; 
  
  final List<String> _filters = ["All", "Songs", "Artists", "Albums", "Playlists"];

  bool _isLoading = false;
  bool _hasSearched = false;
  
  List<Song> _songResults = [];
  List<Artist> _artistResults = [];
  List<Album> _albumResults = [];
  List<Playlist> _playlistResults = [];

  Future<void> _performSearch() async {
    final query = _searchController.text.trim().toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _songResults.clear();
        _artistResults.clear();
        _albumResults.clear();
        _playlistResults.clear();
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final databaseService = widget.testDatabaseService ?? DatabaseService(databaseFactory: databaseFactory);
    if (!databaseService.isOpen()) await databaseService.open();

    final songsResult = await databaseService.getSongs();
    final artistsResult = await databaseService.getArtists();
    final albumsResult = await databaseService.getAlbums();
    final playlistsResult = await databaseService.getPlaylists();

    if (!mounted) return;

    setState(() {
      if (songsResult.isSuccess()) {
        _songResults = songsResult.getOrThrow()
            .where((s) => s.title.toLowerCase().contains(query) || 
                         (s.artists.isNotEmpty && s.artists.first.toLowerCase().contains(query)))
            .toList();
      }
      
      if (artistsResult.isSuccess()) {
        _artistResults = artistsResult.getOrThrow()
            .where((a) => a.name.toLowerCase().contains(query))
            .toList();
      }

      if (albumsResult.isSuccess()) {
        _albumResults = albumsResult.getOrThrow()
            .where((a) => a.title.toLowerCase().contains(query))
            .toList();
      }

      if (playlistsResult.isSuccess()) {
        _playlistResults = playlistsResult.getOrThrow()
            .where((p) => p.title.toLowerCase().contains(query))
            .toList();
      }

      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search, 
                decoration: InputDecoration(
                  hintText: 'What can I search?...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch(); 
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                ),
                onSubmitted: (_) => _performSearch(),
                onChanged: (_) {
                  _performSearch(); 
                },
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasSearched
                    ? const Center(
                        child: Text("Enter a search term to find your music", style: TextStyle(color: Colors.grey, fontSize: 16))
                      )
                    : _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_songResults.isEmpty && _artistResults.isEmpty && _albumResults.isEmpty && _playlistResults.isEmpty) {
      return Center(
        child: Text("No results found for '${_searchController.text}'", style: const TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if ((_selectedFilter == "All" || _selectedFilter == "Songs") && _songResults.isNotEmpty)
          _buildResultSection(
            title: "Songs",
            items: _songResults.map((song) => ListTile(
              leading: _buildArtwork(song.imagePath, Icons.music_note),
              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(song.artists.isNotEmpty ? song.artists.first : 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    playlist: _songResults, 
                    initialIndex: _songResults.indexOf(song),
                    // --- FIX: Pass down the mock repository ---
                    testSongRepository: widget.testSongRepository,
                  ),
                ));
              },
            )).toList(),
          ),

        if ((_selectedFilter == "All" || _selectedFilter == "Artists") && _artistResults.isNotEmpty)
          _buildResultSection(
            title: "Artists",
            items: _artistResults.map((artist) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ArtistDetailScreen(
                    artistName: artist.name,
                    // --- FIX: Pass down the mock repository ---
                    testSongRepository: widget.testSongRepository,
                  ),
                ));
              },
            )).toList(),
          ),

        if ((_selectedFilter == "All" || _selectedFilter == "Albums") && _albumResults.isNotEmpty)
          _buildResultSection(
            title: "Albums",
            items: _albumResults.map((album) => ListTile(
              leading: const Icon(Icons.album, size: 40), 
              title: Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => AlbumDetailScreen(
                    albumName: album.title,
                    // --- FIX: Pass down the mock repository ---
                    testSongRepository: widget.testSongRepository,
                  ),
                ));
              },
            )).toList(),
          ),

        if ((_selectedFilter == "All" || _selectedFilter == "Playlists") && _playlistResults.isNotEmpty)
          _buildResultSection(
            title: "Playlists",
            items: _playlistResults.map((playlist) => ListTile(
              leading: const Icon(Icons.queue_music, size: 40),
              title: Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PlaylistDetailScreen(
                    playlistTitle: playlist.title, 
                    initialIsPinned: false, 
                    playlistId: playlist.id,
                    // --- FIX: Pass down the mock repositories ---
                    testDatabaseService: widget.testDatabaseService,
                    testSongRepository: widget.testSongRepository,
                    testPlaylistRepository: widget.testPlaylistRepository,
                  ),
                ));
              },
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildResultSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        ...items,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildArtwork(String? path, IconData fallbackIcon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        width: 50,
        height: 50,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: path != null
            ? Image.file(File(path), fit: BoxFit.cover)
            : Icon(fallbackIcon),
      ),
    );
  }
}