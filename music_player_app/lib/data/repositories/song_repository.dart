import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:result_dart/result_dart.dart';

class SongRepository {
  SongRepository({required DatabaseService database}) : _database = database;

  final DatabaseService _database;

  Future<Result<List<Song>>> getSongs() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getSongs();
  }

  Future<Result<void>> insertSong({
    required String title,
    String? genre,
    int? year,
    int? bitrate,
    int? trackNumber,
    required String path,
    String? imageId,
    required String albumTitle,
    required List<String> songArtistNames,
    required List<String> albumArtistNames,
  }) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.insertSong(
      title: title,
      path: path,
      albumTitle: albumTitle,
      songArtistNames: songArtistNames,
      albumArtistNames: albumArtistNames,
      genre: genre,
      year: year,
      bitrate: bitrate,
      trackNumber: trackNumber,
      imageId: imageId,
    );
  }

  Future<Result<void>> deleteSong(int songId) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.deleteSong(songId);
  }
}
