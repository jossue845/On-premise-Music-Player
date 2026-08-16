import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:http/http.dart' as http;
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/utils/tag_utils.dart';
import 'package:result_dart/result_dart.dart';
import 'package:music_player_app/data/services/audiodb_service.dart';
import 'package:music_player_app/data/services/lrclib_service.dart';

class SongRepository {
  final DatabaseService _database;

  SongRepository({required DatabaseService database}) : _database = database;

  Future<Result<List<Song>>> getSongs({
    int? albumId,
    int? artistId,
    int? playlistId,
  }) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getSongs(
      albumId: albumId,
      artistId: artistId,
      playlistId: playlistId,
    );
  }

  Future<Result<Song>> fetchAndSaveMissingArtwork(Song song) async {
    if (song.imagePath != null && song.imagePath!.isNotEmpty) {
      return Success(song);
    }

    final adbService = AudioDbService();
    
    final artistName = song.artists.isNotEmpty ? song.artists.first : '';
    if (artistName.isEmpty || artistName == 'Unknown Artist' || song.album.isEmpty || song.album == 'Unknown Album') {
      return Failure(Exception("Missing valid album or artist metadata for search."));
    }

    try {
      final searchResult = await adbService.searchAlbum(song.album, artistName);
      if (searchResult.isError()) return Failure(searchResult.exceptionOrNull()!);

      final data = searchResult.getOrThrow();
      final albums = data['album'] as List?;
      
      if (albums == null || albums.isEmpty) {
        return Failure(Exception("No matching album found on TheAudioDB."));
      }

      final artUrl = albums.first['strAlbumThumb'] as String?;
      if (artUrl == null || artUrl.isEmpty) {
        return Failure(Exception("No artwork image found for this album."));
      }

      final response = await http.get(Uri.parse(artUrl));
      if (response.statusCode != 200) {
         return Failure(Exception("Failed to download image."));
      }

      return await editTags(
        oldSong: song,
        pictureBytes: response.bodyBytes,
      );
    } catch (e) {
      return Failure(Exception("Failed to fetch artwork: $e"));
    }
  }
  
  Future<Result<String>> fetchAndSaveLyrics(Song song) async {
    if (song.lyrics != null && song.lyrics!.isNotEmpty) {
      return Success(song.lyrics!);
    }

    if (!_database.isOpen()) {
        await _database.open();
      }
    final lrclibService = LrcLibService();
    final artistName = song.artists.isNotEmpty ? song.artists.first : '';

    if (artistName.isEmpty || artistName == 'Unknown Artist') {
      return Failure(Exception("Valid artist name required to fetch lyrics."));
    }

    try {
      final fetchResult = await lrclibService.getLyrics(
        song.title, 
        artistName,
        albumName: song.album,
      );
      
      if (fetchResult.isError()) return Failure(fetchResult.exceptionOrNull()!);

      final Map<String, dynamic> data = fetchResult.getOrThrow();
      
      final String? synced = data['syncedLyrics'] as String?;
      final String? plain = data['plainLyrics'] as String?;
      
      if ((synced == null || synced.trim().isEmpty) && 
          (plain == null || plain.trim().isEmpty)) {
        return Failure(Exception("Lyrics not found on LRCLIB."));
      }

      final String fetchedLyrics = (synced != null && synced.trim().isNotEmpty) 
          ? synced 
          : plain!;

      final updatedSong = song.copyWith(lyrics: fetchedLyrics);
      await _database.updateSong(updatedSong); 

      return Success(fetchedLyrics);
    } catch (e) {
      return Failure(Exception("Failed to process lyrics: $e"));
    }
  }

  Future<Result<void>> incrementPlayCount(int songId) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.incrementPlayCount(songId);
  }

  /// Updates [oldSong] with the provided metadata.
  Future<Result<Song>> editTags({
    required Song oldSong,
    String? newTitle,
    String? newGenre,
    int? newYear,
    int? newTrackNumber,
    String? newAlbumTitle,
    List<String>? newSongArtistNames,
    List<String>? newAlbumArtistNames,
    Uint8List? pictureBytes,
  }) async {
    Tag? oldTag = await AudioTags.read(oldSong.path);

    oldTag ??= Tag(
      title: oldSong.title,
      trackArtist: oldSong.artists.isNotEmpty ? oldSong.artists.first : 'Unknown',
      album: oldSong.album.isNotEmpty ? oldSong.album : 'Unknown Album',
      pictures: []
    );

    List<Picture> songPics = oldTag.pictures;

    if (pictureBytes != null) {
      songPics.removeWhere((p) => p.pictureType == PictureType.coverFront);
      songPics.add(
        Picture(
          bytes: pictureBytes,
          mimeType: null,
          pictureType: PictureType.coverFront,
        ),
      );
    }

    Tag tag = Tag(
      title: (newTitle != null) ? newTitle : oldSong.title,
      trackArtist: (newSongArtistNames != null)
          ? newSongArtistNames.join("; ")
          : oldSong.artists.join("; "),
      album: (newAlbumTitle != null) ? newAlbumTitle : oldSong.album,
      albumArtist: (newAlbumArtistNames != null)
          ? newAlbumArtistNames.join("; ")
          : (oldTag.albumArtist != null)
          ? TagUtils.parseArtists(oldTag.albumArtist!).join(";")
          : null,
      genre: (newGenre != null) ? newGenre : oldSong.genre,
      year: (newYear != null) ? newYear : oldSong.year,
      trackNumber: (newTrackNumber != null)
          ? newTrackNumber
          : oldSong.trackNumber,
      pictures: songPics,
      trackTotal: oldTag.trackTotal,
      discNumber: oldTag.discNumber,
      duration: oldTag.duration,
      discTotal: oldTag.discTotal,
      bpm: oldTag.bpm,
      lyrics: oldTag.lyrics,
    );

    final String? imagePath = (pictureBytes != null)
        ? (await TagUtils.storePicture(pictureBytes)).getOrThrow()
        : null;

    try {
      await AudioTags.write(oldSong.path, tag);
    } on Exception catch (e) {
      stderr.writeln(e);
      return Failure(Exception("Failed to edit song tags."));
    }

    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.updateTags(
      oldSong: oldSong,
      newTitle: newTitle,
      newGenre: newGenre,
      newYear: newYear,
      newTrackNumber: newTrackNumber,
      newAlbumTitle: newAlbumTitle,
      newSongArtistNames: newSongArtistNames,
      newAlbumArtistNames: newAlbumArtistNames,
      newImagePath: imagePath,
    );
  }

  /// Sets the favorite status of the song identified by [songId] to [favorite].
  Future<Result<void>> setFavoriteStatus(int songId, bool favorite) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.setFavoriteStatus(songId, favorite);
  }

  /// Batch validates all songs against TheAudioDB and updates their tags.
  Future<int> validateAndFixAllSongs({Function(int current, int total)? onProgress}) async {
    final songsResult = await getSongs();
    if (songsResult.isError()) return 0;

    final songs = songsResult.getOrThrow();
    int updatedCount = 0;

    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      onProgress?.call(i + 1, songs.length);

      final result = await validateAndFixID3Tags(song);
      if (result.isSuccess()) {
        updatedCount++;
      }
      
      await Future.delayed(const Duration(milliseconds: 1200)); 
    }

    return updatedCount;
  }

  //// Validates a song against TheAudioDB, overwrites the physical ID3 tags, 
  /// and updates the local SQLite database.
  Future<Result<Song>> validateAndFixID3Tags(Song currentSong) async {
    final adbService = AudioDbService();
    final artistName = currentSong.artists.isNotEmpty ? currentSong.artists.first : '';

    if (artistName.isEmpty || artistName == 'Unknown Artist') {
      return Failure(Exception("Valid artist name required for validation."));
    }

    try {
      final searchResult = await adbService.searchTrack(currentSong.title, artistName);
      if (searchResult.isError()) return Failure(searchResult.exceptionOrNull()!);

      final data = searchResult.getOrThrow();
      final tracks = data['track'] as List?;

      if (tracks == null || tracks.isEmpty) {
        return Failure(Exception("No matching track found on TheAudioDB."));
      }

      final match = tracks.first;
      final newTitle = match['strTrack'] as String? ?? currentSong.title;
      final newArtist = match['strArtist'] as String? ?? artistName;
      final newAlbum = match['strAlbum'] as String? ?? currentSong.album;
      final newGenre = match['strGenre'] as String?;

      // --- FIX: Force fetch artwork directly from the Album ID ---
      Uint8List? pictureBytes;
      String? artUrl;
      
      final albumIdStr = match['idAlbum'] as String?;
      
      // If we have an exact album ID, use it to fetch the artwork
      if (albumIdStr != null && albumIdStr.isNotEmpty) {
        // We can bypass a full search and just use the exact album endpoint if the service supports it.
        // However, since we only have searchAlbum exposed in our service right now:
        final albumResult = await adbService.searchAlbum(newAlbum, newArtist);
        if (albumResult.isSuccess()) {
           final albumData = albumResult.getOrThrow();
           final albums = albumData['album'] as List?;
           if (albums != null && albums.isNotEmpty) {
             // Ensure we grab the thumbnail from the exact matching album
             final targetAlbum = albums.firstWhere(
                (a) => a['idAlbum'] == albumIdStr, 
                orElse: () => albums.first
             );
             artUrl = targetAlbum['strAlbumThumb'] as String?;
           }
        }
      }

      // Download the image bytes if a URL was found
      if (artUrl != null && artUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(artUrl));
        if (response.statusCode == 200) {
          pictureBytes = response.bodyBytes;
        }
      }

      return await editTags(
        oldSong: currentSong,
        newTitle: newTitle,
        newSongArtistNames: [newArtist],
        newAlbumArtistNames: [newArtist],
        newAlbumTitle: newAlbum.isNotEmpty ? newAlbum : null,
        newGenre: newGenre,
        pictureBytes: pictureBytes, 
      );
    } catch (e) {
      return Failure(Exception("Failed to validate and fix tags: $e"));
    }
  }
}