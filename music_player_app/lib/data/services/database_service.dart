import 'dart:async';
import 'dart:collection';

import 'package:music_player_app/domain/models/album/album.dart';
import 'package:music_player_app/domain/models/artist/artist.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:path/path.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _songTableName = "song";
  static const String _songIdColumnName = "song_id";
  static const String _songTitleColumnName = "song_title";
  static const String _genreColumnName = "genre";
  static const String _yearColumnName = "year";
  static const String _bitrateColumnName = "bitrate";
  static const String _trackNumberColumnName = "track_number";
  static const String _pathColumnName = "path";
  static const String _imageIdColumnName = "image_id";

  static const String _playlistTableName = "playlist";
  static const String _playlistIdColumnName = "playlist_id";
  static const String _playlistTitleColumnName = "playlist_title";

  static const String _playlistTrackTableName = "playlist_track";

  static const String _queuedSongTableName = "queued_song";
  static const String _positionColumnName = "position";
  static const String _currentSongColumnName = "current_song";

  static const String _albumTableName = "album";
  static const String _albumIdColumnName = "album_id";
  static const String _albumTitleColumnName = "album_title";

  static const String _songArtistTableName = "song_artist";

  static const String _albumArtistTableName = "album_artist";

  static const String _artistTableName = "artist";
  static const String _artistIdColumnName = "artist_id";
  static const String _artistNameColumnName = "artist_name";

  Database? _database;
  DatabaseFactory databaseFactory;

  DatabaseService({required this.databaseFactory});

  Future<void> open() async {
    _database = await databaseFactory.openDatabase(
      join(await databaseFactory.getDatabasesPath(), 'app_database.db'),
      options: OpenDatabaseOptions(
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) {
          return db.execute('''
            CREATE TABLE $_playlistTableName($_playlistIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_playlistTitleColumnName TEXT NOT NULL);
            CREATE TABLE $_albumTableName($_albumIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_albumTitleColumnName TEXT NOT NULL);
            CREATE TABLE $_artistTableName($_artistIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_artistNameColumnName TEXT NOT NULL UNIQUE);
            CREATE TABLE $_albumArtistTableName($_albumIdColumnName INTEGER, $_artistIdColumnName INTEGER, PRIMARY KEY($_albumIdColumnName, $_artistIdColumnName),
              FOREIGN KEY($_albumIdColumnName) REFERENCES $_albumTableName($_albumIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE,
              FOREIGN KEY($_artistIdColumnName) REFERENCES $_artistTableName($_artistIdColumnName) ON UPDATE CASCADE ON DELETE RESTRICT);
            CREATE TABLE $_songTableName($_songIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_songTitleColumnName TEXT NOT NULL , $_albumIdColumnName INTEGER,
              $_genreColumnName TEXT, $_yearColumnName INTEGER, $_bitrateColumnName INTEGER, $_trackNumberColumnName INTEGER, $_pathColumnName TEXT NOT NULL,
              $_imageIdColumnName TEXT, FOREIGN KEY($_albumIdColumnName) REFERENCES $_albumTableName($_albumIdColumnName) ON UPDATE CASCADE ON DELETE RESTRICT);
            CREATE TABLE $_songArtistTableName($_songIdColumnName INTEGER, $_artistIdColumnName INTEGER, PRIMARY KEY($_songIdColumnName, $_artistIdColumnName),
              FOREIGN KEY($_songIdColumnName) REFERENCES $_songTableName($_songIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE,
              FOREIGN KEY($_artistIdColumnName) REFERENCES $_artistTableName($_artistIdColumnName) ON UPDATE CASCADE ON DELETE RESTRICT);
            CREATE TABLE $_playlistTrackTableName($_playlistIdColumnName INTEGER, $_songIdColumnName INTEGER, PRIMARY KEY($_playlistIdColumnName, $_songIdColumnName),
              FOREIGN KEY($_playlistIdColumnName) REFERENCES $_playlistTableName($_playlistIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE,
              FOREIGN KEY($_songIdColumnName) REFERENCES $_songTableName($_songIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE);
            CREATE TABLE $_queuedSongTableName($_songIdColumnName INTEGER PRIMARY KEY, $_playlistTitleColumnName TEXT NOT NULL,
              FOREIGN KEY($_songIdColumnName) REFERENCES $_songTableName($_songIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE);
            CREATE TRIGGER delete_album_if_songs_are_deleted
              AFTER DELETE ON $_songTableName
              FOR EACH ROW
              WHEN NOT EXISTS (SELECT 1 FROM $_songTableName WHERE $_albumIdColumnName = OLD.$_albumIdColumnName LIMIT 1)
              BEGIN
                DELETE FROM $_albumTableName WHERE $_albumIdColumnName = OLD.$_albumIdColumnName;
              END;
            CREATE TRIGGER delete_artist_if_no_songs_and_albums_after_song_delete
              AFTER DELETE ON $_songArtistTableName
              FOR EACH ROW
              WHEN NOT EXISTS (SELECT 1 FROM $_songArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1) AND
                NOT EXISTS (SELECT 1 FROM $_albumArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1)
              BEGIN
                DELETE FROM $_artistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName;
              END;
            CREATE TRIGGER delete_artist_if_no_songs_and_albums_after_album_delete
              AFTER DELETE ON $_albumArtistTableName
              FOR EACH ROW
              WHEN NOT EXISTS (SELECT 1 FROM $_songArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1) AND
                NOT EXISTS (SELECT 1 FROM $_albumArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1)
              BEGIN
                DELETE FROM $_artistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName;
              END;
            CREATE TRIGGER delete_artist_if_no_songs_and_albums_after_song_artist_update
              AFTER UPDATE ON $_songArtistTableName
              FOR EACH ROW
              WHEN NOT EXISTS (SELECT 1 FROM $_songArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1) AND
                NOT EXISTS (SELECT 1 FROM $_albumArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1)
              BEGIN
                DELETE FROM $_artistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName;
              END;
            CREATE TRIGGER delete_artist_if_no_songs_and_albums_after_album_artist_update
              AFTER UPDATE ON $_albumArtistTableName
              FOR EACH ROW
              WHEN NOT EXISTS (SELECT 1 FROM $_songArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1) AND
                NOT EXISTS (SELECT 1 FROM $_albumArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1)
              BEGIN
                DELETE FROM $_artistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName;
              END;
            ''');
        },
        version: 1,
      ),
    );
  }

  bool isOpen() {
    return _database != null;
  }

  Future<Result<List<Song>>> getSongs({int? artistId}) async {
    final Map<int, Song> songs = {};

    try {
      final List<Map<String, Object?>> entries;
      // one different entry for each song, song_artist pair
      if (artistId != null) {
        entries = await _database!.rawQuery('''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName WHERE $_songIdColumnName IN
          (SELECT $_songIdColumnName FROM $_songArtistTableName WHERE $_artistIdColumnName = $artistId);
        ''');
      } else {
        entries = await _database!.rawQuery('''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName;
        ''');
      }

      for (final entry in entries) {
        final songId = entry[_songIdColumnName] as int;

        // create song if id not present
        if (!songs.containsKey(songId)) {
          songs.putIfAbsent(
            songId,
            () => Song(
              id: songId,
              title: entry[_songTitleColumnName] as String,
              artists: UnmodifiableListView([
                entry[_artistNameColumnName] as String,
              ]),
              album: entry[_albumTitleColumnName] as String,
              genre: entry[_genreColumnName] as String?,
              year: entry[_yearColumnName] as int?,
              bitrate: entry[_bitrateColumnName] as int?,
              trackNumber: entry[_trackNumberColumnName] as int?,
              path: entry[_pathColumnName] as String,
              imageId: entry[_imageIdColumnName] as String?,
            ),
          );
        } else {
          // simply add the artist to the list if the song is already created
          final artists = List.of(songs[songId]!.artists);
          artists.add(entry[_artistNameColumnName] as String);
          songs[songId] = songs[songId]!.copyWith(
            artists: UnmodifiableListView(artists),
          );
        }
      }

      return Success(songs.values.toList());
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<List<Album>>> getAlbums({int? artistId}) async {
    final Map<int, Album> albums = {};
    late List<Map<String, Object?>> albumArtistsEntries;
    late List<Map<String, Object?>> albumInfoEntries;

    try {
      await _database!.transaction((txn) async {
        if (artistId != null) {
          albumArtistsEntries = await txn.rawQuery('''
          SELECT * FROM $_albumTableName NATURAL JOIN $_albumArtistTableName NATURAL JOIN $_artistTableName WHERE $_albumIdColumnName IN
          (SELECT $_albumIdColumnName FROM $_albumArtistTableName WHERE $_artistIdColumnName = $artistId);
            ''');
          albumInfoEntries = await txn.rawQuery('''
          SELECT DISTINCT $_albumIdColumnName, $_imageIdColumnName, $_yearColumnName FROM $_songTableName WHERE $_albumIdColumnName IN
          (SELECT $_albumIdColumnName FROM $_albumArtistTableName WHERE $_artistIdColumnName = $artistId);

        ''');
        } else {
          albumArtistsEntries = await txn.rawQuery('''
          SELECT * FROM $_albumTableName NATURAL JOIN $_albumArtistTableName NATURAL JOIN $_artistTableName;
            ''');
          albumInfoEntries = await txn.rawQuery('''
          SELECT DISTINCT $_albumIdColumnName, $_imageIdColumnName, $_yearColumnName FROM $_songTableName;
        ''');
        }
      });

      // create albums with required parameters
      for (final entry in albumArtistsEntries) {
        final albumId = entry[_albumIdColumnName] as int;

        if (!albums.containsKey(albumId)) {
          albums.putIfAbsent(
            albumId,
            () => Album(
              id: albumId,
              title: entry[_albumTitleColumnName] as String,
              albumArtists: UnmodifiableListView([
                entry[_artistNameColumnName] as String,
              ]),
            ),
          );
        } else {
          final artists = List.of(albums[albumId]!.albumArtists);
          artists.add(entry[_artistNameColumnName] as String);
          albums[albumId] = albums[albumId]!.copyWith(
            albumArtists: UnmodifiableListView(artists),
          );
        }
      }

      // add image and year
      for (final entry in albumInfoEntries) {
        final albumId = entry[_albumIdColumnName] as int;
        if (albums.containsKey(albumId)) {
          albums[albumId] = albums[albumId]!.copyWith(
            year: entry[_yearColumnName] as int?,
            imageId: entry[_imageIdColumnName] as String?,
          );
        }
      }

      return Success(albums.values.toList());
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<List<Artist>>> getArtists() async {
    try {
      final entries = await _database!.rawQuery('''
          SELECT * FROM $_artistTableName;
        ''');
      final list = entries
          .map(
            (element) => Artist(
              id: element[_artistIdColumnName] as int,
              name: element[_artistNameColumnName] as String,
            ),
          )
          .toList();
      return Success(list);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<int>> _insertSong({
    required DatabaseExecutor executor,
    required String title,
    required int albumId,
    String? genre,
    int? year,
    int? bitrate,
    int? trackNumber,
    required String path,
    String? imageId,
  }) async {
    try {
      final id = await executor.insert(_songTableName, {
        _songTitleColumnName: title,
        _albumIdColumnName: albumId,
        _genreColumnName: genre,
        _yearColumnName: year,
        _bitrateColumnName: bitrate,
        _trackNumberColumnName: trackNumber,
        _pathColumnName: path,
        _imageIdColumnName: imageId,
      });
      return Success(id);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<int>> _insertAlbum({
    required DatabaseExecutor executor,
    required String title,
  }) async {
    try {
      final id = await executor.insert(_albumTableName, {
        _albumTitleColumnName: title,
      });
      return Success(id);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<int>> _insertArtist(
    DatabaseExecutor executor,
    String artistName,
  ) async {
    try {
      int id = await executor.insert(_artistTableName, {
        _artistNameColumnName: artistName,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      if (id == 0) {
        final result = await executor.query(
          _artistTableName,
          columns: [_artistIdColumnName],
          where: "$_artistNameColumnName = ?",
          whereArgs: [artistName],
        );
        if (result.isNotEmpty) {
          id = result.first[_artistIdColumnName] as int;
        }
      }
      return Success(id);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<void>> _insertSongArist(
    DatabaseExecutor executor,
    int songId,
    int artistId,
  ) async {
    try {
      await executor.insert(_songArtistTableName, {
        _songIdColumnName: songId,
        _artistIdColumnName: artistId,
      });
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<void>> _insertAlbumArist(
    DatabaseExecutor executor,
    int albumId,
    int artistId,
  ) async {
    try {
      await executor.insert(_albumArtistTableName, {
        _albumIdColumnName: albumId,
        _artistIdColumnName: artistId,
      });
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
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
    try {
      await _database!.transaction((txn) async {
        final List<int> songArtistIds = [];
        final List<int> albumArtistIds = [];
        int albumId = -1;
        final int songId;
        final Map<int, List<int>> potentialAlbums = {};

        // Insert artists and get the ids
        for (final artist in songArtistNames) {
          songArtistIds.add(await _insertArtist(txn, artist).getOrThrow());
        }
        for (final artist in albumArtistNames) {
          albumArtistIds.add(await _insertArtist(txn, artist).getOrThrow());
        }

        // Get albums titled $albumTitle and map them to their artists
        final albumQueryResult = await txn.rawQuery(
          "SELECT * FROM $_albumTableName NATURAL JOIN $_albumArtistTableName WHERE $_albumTitleColumnName = '$albumTitle';",
        );
        for (final element in albumQueryResult) {
          final potentialAlbumId = element[_albumIdColumnName] as int;
          if (!potentialAlbums.containsKey(potentialAlbumId)) {
            potentialAlbums.putIfAbsent(potentialAlbumId, () => []);
          }
          potentialAlbums[potentialAlbumId]!.add(
            element[_artistIdColumnName] as int,
          );
        }

        // Find the correct album, meaning the one with the same album artists
        for (final album in potentialAlbums.keys) {
          if (potentialAlbums[album]!.length == albumArtistIds.length &&
              albumArtistIds.toSet().containsAll(
                potentialAlbums[album]!.toSet(),
              )) {
            albumId = album;
            break;
          }
        }

        // If the album was not present, create it and insert album artists
        if (albumId == -1) {
          albumId = await _insertAlbum(
            executor: txn,
            title: albumTitle,
          ).getOrThrow();

          for (final artist in albumArtistIds) {
            final result = await _insertAlbumArist(txn, albumId, artist);
            if (result.isError()) {
              throw Exception(result.exceptionOrNull());
            }
          }
        }

        // Insert song and song artists
        songId = await _insertSong(
          executor: txn,
          title: title,
          albumId: albumId,
          path: path,
          genre: genre,
          year: year,
          bitrate: bitrate,
          trackNumber: trackNumber,
          imageId: imageId,
        ).getOrThrow();

        for (final artist in songArtistIds) {
          final result = await _insertSongArist(txn, songId, artist);
          if (result.isError()) {
            throw Exception(result.exceptionOrNull());
          }
        }
      });
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<void>> deleteSong(int songId) async {
    try {
      final rowsDeleted = await _database!.delete(
        _songTableName,
        where: "$_songIdColumnName = ?",
        whereArgs: [songId],
      );
      if (rowsDeleted == 0) {
        return Failure(Exception("No song found with id $songId"));
      }
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
