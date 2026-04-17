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
  static const String _imagePathColumnName = "image_path";

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

  /// Opens the database.
  ///
  /// Creates the database if it doesn't exist.
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
            CREATE TABLE $_songTableName($_songIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_songTitleColumnName TEXT NOT NULL , $_albumIdColumnName INTEGER NOT NULL,
              $_genreColumnName TEXT, $_yearColumnName INTEGER, $_bitrateColumnName INTEGER, $_trackNumberColumnName INTEGER, $_pathColumnName TEXT NOT NULL,
              $_imagePathColumnName TEXT, FOREIGN KEY($_albumIdColumnName) REFERENCES $_albumTableName($_albumIdColumnName) ON UPDATE CASCADE ON DELETE RESTRICT);
            CREATE TABLE $_songArtistTableName($_songIdColumnName INTEGER, $_artistIdColumnName INTEGER, PRIMARY KEY($_songIdColumnName, $_artistIdColumnName),
              FOREIGN KEY($_songIdColumnName) REFERENCES $_songTableName($_songIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE,
              FOREIGN KEY($_artistIdColumnName) REFERENCES $_artistTableName($_artistIdColumnName) ON UPDATE CASCADE ON DELETE RESTRICT);
            CREATE TABLE $_playlistTrackTableName($_playlistIdColumnName INTEGER, $_songIdColumnName INTEGER, PRIMARY KEY($_playlistIdColumnName, $_songIdColumnName),
              FOREIGN KEY($_playlistIdColumnName) REFERENCES $_playlistTableName($_playlistIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE,
              FOREIGN KEY($_songIdColumnName) REFERENCES $_songTableName($_songIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE);
            CREATE TABLE $_queuedSongTableName($_songIdColumnName INTEGER PRIMARY KEY, $_positionColumnName INTEGER NOT NULL, $_currentSongColumnName INTEGER NOT NULL,
              FOREIGN KEY($_songIdColumnName) REFERENCES $_songTableName($_songIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE);
            CREATE TRIGGER delete_album_if_songs_are_deleted
              AFTER DELETE ON $_songTableName
              FOR EACH ROW
              WHEN NOT EXISTS (SELECT 1 FROM $_songTableName WHERE $_albumIdColumnName = OLD.$_albumIdColumnName LIMIT 1)
              BEGIN
                DELETE FROM $_albumTableName WHERE $_albumIdColumnName = OLD.$_albumIdColumnName;
              END;
            CREATE TRIGGER delete_album_if_songs_no_longer_reference_it
              AFTER UPDATE ON $_songTableName
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

  /// Whether the database is open.
  bool isOpen() {
    return _database != null;
  }

  /// Returns the songs in the database associated to an album and at least one song artist.
  ///
  /// Is's required for an inserted song to have those attributes, therefore no song is expected to be ignored.
  ///
  /// Returns the songs made by the artist identified by [artistId] when it is not null.
  ///
  /// Returns the songs in the album identified by [albumId] when it is not null.
  Future<Result<List<Song>>> getSongs({int? artistId, int? albumId}) async {
    final Map<int, Song> songs = {};

    try {
      final List<Map<String, Object?>> entries;

      // Get the songs, with a different entry for each song, song_artist pair.
      if (artistId != null) {
        entries = await _database!.rawQuery('''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName WHERE $_songIdColumnName IN
          (SELECT $_songIdColumnName FROM $_songArtistTableName WHERE $_artistIdColumnName = $artistId);
        ''');
      } else if (albumId != null) {
        entries = await _database!.rawQuery('''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName WHERE $_albumIdColumnName = $albumId;
        ''');
      } else {
        entries = await _database!.rawQuery('''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName;
        ''');
      }

      for (final entry in entries) {
        final songId = entry[_songIdColumnName] as int;

        // Create and add song if it's id is not present in the map.
        if (!songs.containsKey(songId)) {
          songs[songId] = Song(
            id: songId,
            title: entry[_songTitleColumnName] as String,
            artists: UnmodifiableListView([
              entry[_artistNameColumnName] as String,
            ]),
            album: entry[_albumTitleColumnName] as String,
            albumId: entry[_albumIdColumnName] as int,
            genre: entry[_genreColumnName] as String?,
            year: entry[_yearColumnName] as int?,
            bitrate: entry[_bitrateColumnName] as int?,
            trackNumber: entry[_trackNumberColumnName] as int?,
            path: entry[_pathColumnName] as String,
            imagePath: entry[_imagePathColumnName] as String?,
          );
        } else {
          // Add the artist to the list of song artists if the song is already created.
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

  /// Returns the albums in the database associated to at least one album artist.
  ///
  /// Is's required for an inserted album to have that attribute, therefore no album is expected to be ignored.
  ///
  /// Returns the albums made by the artist identified by [artistId] when it is not null.
  Future<Result<List<Album>>> getAlbums({int? artistId}) async {
    final Map<int, Album> albums = {};
    late List<Map<String, Object?>> albumArtistsEntries;
    late List<Map<String, Object?>> albumInfoEntries;

    try {
      // Get the albums and the associated metadata.
      await _database!.transaction((txn) async {
        if (artistId != null) {
          albumArtistsEntries = await txn.rawQuery('''
          SELECT * FROM $_albumTableName NATURAL JOIN $_albumArtistTableName NATURAL JOIN $_artistTableName WHERE $_albumIdColumnName IN
          (SELECT $_albumIdColumnName FROM $_albumArtistTableName WHERE $_artistIdColumnName = $artistId);
            ''');
          albumInfoEntries = await txn.rawQuery('''
          SELECT DISTINCT $_albumIdColumnName, $_imagePathColumnName, $_yearColumnName FROM $_songTableName WHERE $_albumIdColumnName IN
          (SELECT $_albumIdColumnName FROM $_albumArtistTableName WHERE $_artistIdColumnName = $artistId);

        ''');
        } else {
          albumArtistsEntries = await txn.rawQuery('''
          SELECT * FROM $_albumTableName NATURAL JOIN $_albumArtistTableName NATURAL JOIN $_artistTableName;
            ''');
          albumInfoEntries = await txn.rawQuery('''
          SELECT DISTINCT $_albumIdColumnName, $_imagePathColumnName, $_yearColumnName FROM $_songTableName;
        ''');
        }
      });

      for (final entry in albumArtistsEntries) {
        final albumId = entry[_albumIdColumnName] as int;

        // Create and add album if it's id is not present in the map.
        if (!albums.containsKey(albumId)) {
          albums[albumId] = Album(
            id: albumId,
            title: entry[_albumTitleColumnName] as String,
            albumArtists: UnmodifiableListView([
              entry[_artistNameColumnName] as String,
            ]),
          );
        } else {
          // Add the artist to the list of album artists if the song is already created.
          final artists = List.of(albums[albumId]!.albumArtists);
          artists.add(entry[_artistNameColumnName] as String);
          albums[albumId] = albums[albumId]!.copyWith(
            albumArtists: UnmodifiableListView(artists),
          );
        }
      }

      // Add image and year to the albums.
      for (final entry in albumInfoEntries) {
        final albumId = entry[_albumIdColumnName] as int;
        if (albums.containsKey(albumId)) {
          albums[albumId] = albums[albumId]!.copyWith(
            year: entry[_yearColumnName] as int?,
            imagePath: entry[_imagePathColumnName] as String?,
          );
        }
      }

      return Success(albums.values.toList());
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Returns all the artists in the database.
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

  /// Inserts a row in the song table with the specified metadata.
  ///
  /// Uses the specified database [executor] to perform the insert.
  ///
  /// Returns the id of the inserted song.
  Future<Result<int>> _insertSong({
    required DatabaseExecutor executor,
    required String title,
    required int albumId,
    String? genre,
    int? year,
    int? bitrate,
    int? trackNumber,
    required String path,
    String? imagePath,
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
        _imagePathColumnName: imagePath,
      });
      return Success(id);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Inserts a row in the album table with the specified [title].
  ///
  /// Uses the specified database [executor] to perform the insert.
  ///
  /// Returns the id of the inserted album.
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

  /// Inserts a row in the artist table with the specified [artistName] if it wasn't already present.
  ///
  /// Uses the specified database [executor] to perform the insert.
  ///
  /// Returns the id of the inserted, or already present, artist.
  Future<Result<int>> _insertArtistIfAbsent(
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

  /// Inserts a row in the song artist table with the specified [songId] and [artistId].
  ///
  /// Uses the specified database [executor] to perform the insert.
  Future<Result<void>> _insertSongArtist(
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

  /// Inserts a row in the album artist table with the specified [albumId] and [artistId].
  ///
  /// Uses the specified database [executor] to perform the insert.
  Future<Result<void>> _insertAlbumArtist(
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

  /// Inserts a row in the album table with the specified [albumTitle] if it wasn't already present.
  ///
  /// Checks album equality using [albumTitle] and [albumArtistIds].
  ///
  /// Uses the specified database [executor] to perform the insert.
  ///
  /// Returns the id of the inserted, or already present, album.
  Future<Result<int>> _insertAlbumIfAbsent(
    DatabaseExecutor executor,
    String albumTitle,
    List<int> albumArtistIds,
  ) async {
    try {
      int albumId = -1;
      final Map<int, List<int>> potentialAlbums = {};

      // Get albums titled $albumTitle, with one entry per album, album artist pair.
      final albumQueryResult = await executor.rawQuery(
        "SELECT * FROM $_albumTableName NATURAL JOIN $_albumArtistTableName WHERE $_albumTitleColumnName = '$albumTitle';",
      );

      // Map the album artists to the album ids.
      for (final element in albumQueryResult) {
        final potentialAlbumId = element[_albumIdColumnName] as int;
        potentialAlbums.putIfAbsent(potentialAlbumId, () => []);
        potentialAlbums[potentialAlbumId]!.add(
          element[_artistIdColumnName] as int,
        );
      }

      // Check if the album was already inserted.
      for (final album in potentialAlbums.keys) {
        // Check if the album artists are the same.
        if (potentialAlbums[album]!.length == albumArtistIds.length &&
            albumArtistIds.toSet().containsAll(
              potentialAlbums[album]!.toSet(),
            )) {
          albumId = album;
          break;
        }
      }

      // If the album was not present, create it and insert the album artists.
      if (albumId == -1) {
        albumId = await _insertAlbum(
          executor: executor,
          title: albumTitle,
        ).getOrThrow();

        for (final artist in albumArtistIds) {
          final result = await _insertAlbumArtist(executor, albumId, artist);
          if (result.isError()) {
            throw Exception(result.exceptionOrNull());
          }
        }
      }
      return Success(albumId);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Inserts a song and all of the entities related to it into the database.
  ///
  /// The following tables are affected:
  /// song, song artist
  /// album, artist, album artist if they are not already present
  Future<Result<void>> insertSong({
    required String title,
    String? genre,
    int? year,
    int? bitrate,
    int? trackNumber,
    required String path,
    String? imagePath,
    required String albumTitle,
    required List<String> songArtistNames,
    required List<String> albumArtistNames,
  }) async {
    if (songArtistNames.isEmpty ||
        albumArtistNames.isEmpty ||
        songArtistNames.where((a) => a.isEmpty).isNotEmpty ||
        albumArtistNames.where((a) => a.isEmpty).isNotEmpty) {
      return Failure(
        Exception(
          "songArtistNames and albumArtistNames cannot be empty or contain empty strings",
        ),
      );
    }
    if (title.isEmpty || path.isEmpty || albumTitle.isEmpty) {
      return Failure(
        Exception("title, path and albumTitle cannot be empty strings"),
      );
    }

    try {
      await _database!.transaction((txn) async {
        final List<int> songArtistIds = [];
        final List<int> albumArtistIds = [];
        final int albumId;
        final int songId;

        // Insert artists and save their ids.
        for (final artist in songArtistNames) {
          songArtistIds.add(
            await _insertArtistIfAbsent(txn, artist).getOrThrow(),
          );
        }
        for (final artist in albumArtistNames) {
          albumArtistIds.add(
            await _insertArtistIfAbsent(txn, artist).getOrThrow(),
          );
        }

        // Insert album and get its id.
        albumId = await _insertAlbumIfAbsent(
          txn,
          albumTitle,
          albumArtistIds,
        ).getOrThrow();

        // Insert song and song artists.
        songId = await _insertSong(
          executor: txn,
          title: title,
          albumId: albumId,
          path: path,
          genre: genre,
          year: year,
          bitrate: bitrate,
          trackNumber: trackNumber,
          imagePath: imagePath,
        ).getOrThrow();

        for (final artist in songArtistIds) {
          final result = await _insertSongArtist(txn, songId, artist);
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

  /// Deletes the song identified by [songId] from the database.
  ///
  /// The related metadata is handled by triggers and foreign key actions.
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

  /// Updates [oldSong] with the specified metadata.
  ///
  /// Returns a new [Song] with the updated metadata.
  Future<Result<Song>> updateTags({
    required Song oldSong,
    String? newTitle,
    String? newGenre,
    int? newYear,
    int? newTrackNumber,
    String? newAlbumTitle,
    List<String>? newSongArtistNames,
    List<String>? newAlbumArtistNames,
  }) async {
    Song newSong = oldSong;
    try {
      await _database!.transaction((txn) async {
        final List<int> songArtistIds = [];
        final List<int> albumArtistIds = [];

        // Update song artists.
        if (newSongArtistNames != null &&
            newSongArtistNames.isNotEmpty &&
            newSongArtistNames.where((a) => a.isEmpty).isEmpty) {
          // Delete old song artists.
          await txn.delete(
            _songArtistTableName,
            where: "$_songIdColumnName = ?",
            whereArgs: [oldSong.id],
          );

          // Insert artists and save their ids.
          for (final artist in newSongArtistNames) {
            songArtistIds.add(
              await _insertArtistIfAbsent(txn, artist).getOrThrow(),
            );
          }

          // Insert song artists.
          for (final artistId in songArtistIds) {
            final result = await _insertSongArtist(txn, oldSong.id, artistId);
            if (result.isError()) {
              throw Exception(result.exceptionOrNull());
            }
          }
        }

        if (newAlbumTitle != null && newAlbumTitle.isNotEmpty) {
          // Get album artist ids.
          final albumArtistEntries = await txn.query(
            _albumArtistTableName,
            where: "$_albumIdColumnName = ?",
            whereArgs: [oldSong.albumId],
          );

          final albumId = await _insertAlbumIfAbsent(
            txn,
            newAlbumTitle,
            albumArtistEntries
                .map((e) => e[_artistIdColumnName] as int)
                .toList(),
          ).getOrThrow();

          // Update song tuple with the new albumId.
          txn.update(
            _songTableName,
            Map.fromEntries([MapEntry(_albumIdColumnName, albumId)]),
            where: "$_albumIdColumnName = ?",
            whereArgs: [oldSong.albumId],
          );

          newSong = newSong.copyWith(albumId: albumId);
        }

        // Update album artists.
        if (newAlbumArtistNames != null &&
            newAlbumArtistNames.isNotEmpty &&
            newAlbumArtistNames.where((a) => a.isEmpty).isEmpty) {
          // Delete old album artists.
          await txn.delete(
            _albumArtistTableName,
            where: "$_albumIdColumnName = ?",
            whereArgs: [newSong.albumId],
          );

          // Insert artists and save their ids.
          for (final artist in newAlbumArtistNames) {
            albumArtistIds.add(
              await _insertArtistIfAbsent(txn, artist).getOrThrow(),
            );
          }

          // Insert album artists.
          for (final artistId in albumArtistIds) {
            final result = await _insertAlbumArtist(
              txn,
              newSong.albumId,
              artistId,
            );
            if (result.isError()) {
              throw Exception(result.exceptionOrNull());
            }
          }
        }

        // Update title.
        if (newTitle != null && newTitle.isNotEmpty) {
          await txn.update(
            _songTableName,
            Map.fromEntries([MapEntry(_songTitleColumnName, newTitle)]),
            where: "$_songIdColumnName = ?",
            whereArgs: [oldSong.id],
          );
          newSong = newSong.copyWith(title: newTitle);
        }

        // Update genre.
        if (newGenre != null && newGenre.isNotEmpty) {
          await txn.update(
            _songTableName,
            Map.fromEntries([MapEntry(_genreColumnName, newGenre)]),
            where: "$_songIdColumnName = ?",
            whereArgs: [oldSong.id],
          );
          newSong = newSong.copyWith(genre: newGenre);
        }

        // Update year.
        if (newYear != null) {
          await txn.update(
            _songTableName,
            Map.fromEntries([MapEntry(_yearColumnName, newYear)]),
            where: "$_songIdColumnName = ?",
            whereArgs: [oldSong.id],
          );
          newSong = newSong.copyWith(year: newYear);
        }

        // Update track number.
        if (newTrackNumber != null) {
          await txn.update(
            _songTableName,
            Map.fromEntries([MapEntry(_trackNumberColumnName, newTrackNumber)]),
            where: "$_songIdColumnName = ?",
            whereArgs: [oldSong.id],
          );
          newSong = newSong.copyWith(trackNumber: newTrackNumber);
        }
      });

      return Success(newSong);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
