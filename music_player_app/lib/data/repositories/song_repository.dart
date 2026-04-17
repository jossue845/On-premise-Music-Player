import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:result_dart/result_dart.dart';

class SongRepository {
  final DatabaseService _database;

  SongRepository({required DatabaseService database}) : _database = database;

  /// Returns all the songs.
  Future<Result<List<Song>>> getSongs() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getSongs();
  }

  Future<Result<Song>> editTags({
    required Song oldSong,
    String? newTitle,
    String? newGenre,
    int? newYear,
    int? newTrackNumber,
    String? newAlbumTitle,
    List<String>? newSongArtistNames,
    List<String>? newAlbumArtistNames,
  }) async {
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
    );
  }
}
