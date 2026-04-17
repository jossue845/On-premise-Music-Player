import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/album/album.dart';
import 'package:music_player_app/domain/models/artist/artist.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:result_dart/result_dart.dart';

class ArtistRepository {
  final DatabaseService _database;

  ArtistRepository({required DatabaseService database}) : _database = database;

  /// Returns all the artists.
  Future<Result<List<Artist>>> getArtists() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getArtists();
  }

  /// Returns all the songs that have [artistId] as artist.
  Future<Result<List<Song>>> getSongs(int artistId) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getSongs(artistId: artistId);
  }

  /// Returns all the albums that have [artistId] as album artist.
  Future<Result<List<Album>>> getAlbums(int artistId) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getAlbums(artistId: artistId);
  }
}
