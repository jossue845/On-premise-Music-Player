import 'dart:async';
import 'dart:collection';

import 'package:music_player_app/domain/models/album/album.dart';
import 'package:music_player_app/domain/models/artist/artist.dart';
import 'package:music_player_app/domain/models/playlist/playlist.dart';
import 'package:music_player_app/domain/models/queue/song_queue.dart';
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

  static const String _keyValueStoreTableName = "kv_store";
  static const String _keyColumnName = "key";
  static const String _valueColumnName = "value";

  Database? _database;
  DatabaseFactory databaseFactory;

  DatabaseService({required this.databaseFactory});

  FutureOr<void> _createOrUpdateDb(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('''
         CREATE TABLE IF NOT EXISTS $_playlistTableName($_playlistIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_playlistTitleColumnName TEXT NOT NULL);
          ''');
      await txn.execute('''
         CREATE TABLE IF NOT EXISTS $_albumTableName($_albumIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_albumTitleColumnName TEXT NOT NULL);
          ''');
      await txn.execute('''
         CREATE TABLE IF NOT EXISTS $_artistTableName($_artistIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_artistNameColumnName TEXT NOT NULL UNIQUE);
          ''');
      await txn.execute('''
         CREATE TABLE IF NOT EXISTS $_albumArtistTableName($_albumIdColumnName INTEGER, $_artistIdColumnName INTEGER, PRIMARY KEY($_albumIdColumnName, $_artistIdColumnName),
           FOREIGN KEY($_albumIdColumnName) REFERENCES $_albumTableName($_albumIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE,
           FOREIGN KEY($_artistIdColumnName) REFERENCES $_artistTableName($_artistIdColumnName) ON UPDATE CASCADE ON DELETE RESTRICT);
          ''');
      await txn.execute('''
         CREATE TABLE IF NOT EXISTS $_songTableName($_songIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_songTitleColumnName TEXT NOT NULL , $_albumIdColumnName INTEGER NOT NULL,
           $_genreColumnName TEXT, $_yearColumnName INTEGER, $_trackNumberColumnName INTEGER, $_pathColumnName TEXT NOT NULL UNIQUE,
           $_imagePathColumnName TEXT, FOREIGN KEY($_albumIdColumnName) REFERENCES $_albumTableName($_albumIdColumnName) ON UPDATE CASCADE ON DELETE RESTRICT);
          ''');
      await txn.execute('''
         CREATE TABLE IF NOT EXISTS $_songArtistTableName($_songIdColumnName INTEGER, $_artistIdColumnName INTEGER, PRIMARY KEY($_songIdColumnName, $_artistIdColumnName),
           FOREIGN KEY($_songIdColumnName) REFERENCES $_songTableName($_songIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE,
           FOREIGN KEY($_artistIdColumnName) REFERENCES $_artistTableName($_artistIdColumnName) ON UPDATE CASCADE ON DELETE RESTRICT);
          ''');
      await txn.execute('''
         CREATE TABLE IF NOT EXISTS $_playlistTrackTableName($_playlistIdColumnName INTEGER, $_songIdColumnName INTEGER, PRIMARY KEY($_playlistIdColumnName, $_songIdColumnName),
           FOREIGN KEY($_playlistIdColumnName) REFERENCES $_playlistTableName($_playlistIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE,
           FOREIGN KEY($_songIdColumnName) REFERENCES $_songTableName($_songIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE);
          ''');
      await txn.execute('''
         CREATE TABLE IF NOT EXISTS $_queuedSongTableName($_songIdColumnName INTEGER PRIMARY KEY, $_positionColumnName INTEGER NOT NULL, $_currentSongColumnName INTEGER NOT NULL,
           FOREIGN KEY($_songIdColumnName) REFERENCES $_songTableName($_songIdColumnName) ON UPDATE CASCADE ON DELETE CASCADE);
          ''');
      await txn.execute('''
         CREATE TABLE IF NOT EXISTS $_keyValueStoreTableName($_keyColumnName TEXT PRIMARY KEY, $_valueColumnName TEXT NOT NULL);
          ''');
      await txn.execute('''
         CREATE TRIGGER IF NOT EXISTS delete_album_if_songs_are_deleted
           AFTER DELETE ON $_songTableName
           FOR EACH ROW
           WHEN NOT EXISTS (SELECT 1 FROM $_songTableName WHERE $_albumIdColumnName = OLD.$_albumIdColumnName LIMIT 1)
           BEGIN
             DELETE FROM $_albumTableName WHERE $_albumIdColumnName = OLD.$_albumIdColumnName;
           END;
          ''');
      await txn.execute('''
         CREATE TRIGGER IF NOT EXISTS delete_album_if_songs_no_longer_reference_it
           AFTER UPDATE ON $_songTableName
           FOR EACH ROW
           WHEN NOT EXISTS (SELECT 1 FROM $_songTableName WHERE $_albumIdColumnName = OLD.$_albumIdColumnName LIMIT 1)
           BEGIN
             DELETE FROM $_albumTableName WHERE $_albumIdColumnName = OLD.$_albumIdColumnName;
           END;
          ''');
      await txn.execute('''
         CREATE TRIGGER IF NOT EXISTS delete_artist_if_no_songs_and_albums_after_song_delete
           AFTER DELETE ON $_songArtistTableName
           FOR EACH ROW
           WHEN NOT EXISTS (SELECT 1 FROM $_songArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1) AND
             NOT EXISTS (SELECT 1 FROM $_albumArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1)
           BEGIN
             DELETE FROM $_artistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName;
           END;
          ''');
      await txn.execute('''
         CREATE TRIGGER IF NOT EXISTS delete_artist_if_no_songs_and_albums_after_album_delete
           AFTER DELETE ON $_albumArtistTableName
           FOR EACH ROW
           WHEN NOT EXISTS (SELECT 1 FROM $_songArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1) AND
             NOT EXISTS (SELECT 1 FROM $_albumArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1)
           BEGIN
             DELETE FROM $_artistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName;
           END;
          ''');
      await txn.execute('''
         CREATE TRIGGER IF NOT EXISTS delete_artist_if_no_songs_and_albums_after_song_artist_update
           AFTER UPDATE ON $_songArtistTableName
           FOR EACH ROW
           WHEN NOT EXISTS (SELECT 1 FROM $_songArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1) AND
             NOT EXISTS (SELECT 1 FROM $_albumArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1)
           BEGIN
             DELETE FROM $_artistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName;
           END;
          ''');
      await txn.execute('''
         CREATE TRIGGER IF NOT EXISTS delete_artist_if_no_songs_and_albums_after_album_artist_update
           AFTER UPDATE ON $_albumArtistTableName
           FOR EACH ROW
           WHEN NOT EXISTS (SELECT 1 FROM $_songArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1) AND
             NOT EXISTS (SELECT 1 FROM $_albumArtistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName LIMIT 1)
           BEGIN
             DELETE FROM $_artistTableName WHERE $_artistIdColumnName = OLD.$_artistIdColumnName;
           END;
          ''');
    });
  }

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
        onCreate: (db, version) async {
          return await _createOrUpdateDb(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          return await _createOrUpdateDb(db);
        },
        version: 5,
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
  Future<Result<List<Song>>> getSongs({
    int? artistId,
    int? albumId,
    int? playlistId,
    String? path,
  }) async {
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
      } else if (path != null) {
        entries = await _database!.rawQuery(
          '''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName WHERE $_pathColumnName = ?;
        ''',
          [path],
        );
      } else if (playlistId != null) {
        entries = await _database!.rawQuery('''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName
          WHERE $_songIdColumnName IN (SELECT $_songIdColumnName FROM $_playlistTrackTableName WHERE $_playlistIdColumnName = $playlistId);
        ''');
      } else {
        entries = await _database!.rawQuery('''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName;
        ''');
      }

      return Success(_processSongQuery(entries));
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Returns the songs with the specified [title], [genre], [year] and [trackNumber].
  Future<Result<List<Song>>> getSongsWith({
    String? title,
    String? genre,
    int? year,
    int? trackNumber,
  }) async {
    try {
      final List<Map<String, Object?>> entries;

      entries = await _database!.rawQuery(
        '''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName
          WHERE $_songTitleColumnName = ? AND $_genreColumnName = ? AND $_yearColumnName = ? AND $_trackNumberColumnName = ?;
        ''',
        [title, genre, year, trackNumber],
      );

      return Success(_processSongQuery(entries));
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  List<Song> _processSongQuery(List<Map<String, Object?>> entries) {
    final Map<int, Song> songs = {};
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
    return songs.values.toList();
  }

  /// Returns the albums in the database associated to at least one album artist.
  ///
  /// Is's required for an inserted album to have that attribute, therefore no album is expected to be ignored.
  ///
  /// Returns the albums made by the artist identified by [artistId] when it is not null.
  Future<Result<List<Album>>> getAlbums({int? artistId, int? songId}) async {
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
        } else if (songId != null) {
          albumArtistsEntries = await txn.rawQuery('''
          SELECT * FROM $_albumTableName NATURAL JOIN $_albumArtistTableName NATURAL JOIN $_artistTableName WHERE $_albumIdColumnName IN
          (SELECT $_albumIdColumnName FROM $_songTableName WHERE $_songIdColumnName = $songId);
            ''');
          albumInfoEntries = await txn.rawQuery('''
          SELECT DISTINCT $_albumIdColumnName, $_imagePathColumnName, $_yearColumnName FROM $_songTableName WHERE $_albumIdColumnName IN
          (SELECT $_albumIdColumnName FROM $_songTableName WHERE $_songIdColumnName = $songId);
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

  /// Returns all the playlists in the database.
  Future<Result<List<Playlist>>> getPlaylists() async {
    try {
      final playlistEntries = await _database!.rawQuery('''
        SELECT $_playlistIdColumnName, $_playlistTitleColumnName, (SELECT $_imagePathColumnName FROM $_songTableName NATURAL JOIN $_playlistTrackTableName PT
          WHERE PT.$_playlistIdColumnName = P.$_playlistIdColumnName LIMIT 1) as $_imagePathColumnName
        FROM $_playlistTableName P;
      ''');
      final playlists = playlistEntries
          .map(
            (element) => Playlist(
              id: element[_playlistIdColumnName] as int,
              title: element[_playlistTitleColumnName] as String,
              imageId: element[_imagePathColumnName] as String?,
            ),
          )
          .toList();
      return Success(playlists);
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

  /// Returns the queue saved in the database.
  Future<Result<SongQueue>> getQueue() async {
    try {
      final List<int> queueList = [];
      int currentSongIndex = 0;

      // Get queue
      final queueEntries = await _database!.query(
        _queuedSongTableName,
        orderBy: _positionColumnName,
      );

      // Build id list and check for current song.
      for (final entry in queueEntries) {
        queueList.add(entry[_songIdColumnName] as int);
        if ((entry[_currentSongColumnName] as int) == 1) {
          currentSongIndex = entry[_positionColumnName] as int;
        }
      }
      return Success(
        SongQueue(
          songIds: UnmodifiableListView(queueList),
          currentSongIndex: currentSongIndex,
        ),
      );
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
        "SELECT * FROM $_albumTableName NATURAL JOIN $_albumArtistTableName WHERE $_albumTitleColumnName = ?;",
        [albumTitle],
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
          (await _insertAlbumArtist(executor, albumId, artist)).getOrThrow();
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
  Future<Result<int>> insertSong({
    required String title,
    String? genre,
    int? year,
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
      late int songId;
      await _database!.transaction((txn) async {
        final List<int> songArtistIds = [];
        final List<int> albumArtistIds = [];
        final int albumId;

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
          trackNumber: trackNumber,
          imagePath: imagePath,
        ).getOrThrow();

        for (final artist in songArtistIds) {
          (await _insertSongArtist(txn, songId, artist)).getOrThrow();
        }
      });
      return Success(songId);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Deletes the songs identified by [songIds] from the database.
  ///
  /// The related metadata is handled by triggers and foreign key actions.
  Future<Result<void>> deleteSongs({
    List<int>? songIds,
    List<String>? songPaths,
  }) async {
    try {
      await _database!.transaction((txn) async {
        final batch = txn.batch();
        if (songIds != null) {
          for (final songId in songIds) {
            batch.delete(
              _songTableName,
              where: "$_songIdColumnName = ?",
              whereArgs: [songId],
            );
          }
          final rowsDeleted = await batch.commit();
          if (rowsDeleted.length != songIds.length) {
            return Failure(Exception("One or more songs not found"));
          }
        } else if (songPaths != null) {
          for (final songPath in songPaths) {
            batch.delete(
              _songTableName,
              where: "$_pathColumnName = ?",
              whereArgs: [songPath],
            );
          }
          final rowsDeleted = await batch.commit();
          if (rowsDeleted.length != songPaths.length) {
            return Failure(Exception("One or more songs not found"));
          }
        }
      });
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
    String? newPath,
    String? newImagePath,
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
            (await _insertSongArtist(txn, oldSong.id, artistId)).getOrThrow();
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
            (await _insertAlbumArtist(
              txn,
              newSong.albumId,
              artistId,
            )).getOrThrow();
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

        // Update path.
        if (newPath != null && newPath.isNotEmpty) {
          await txn.update(
            _songTableName,
            Map.fromEntries([MapEntry(_pathColumnName, newPath)]),
            where: "$_songIdColumnName = ?",
            whereArgs: [oldSong.id],
          );
          newSong = newSong.copyWith(path: newPath);
        }

        // Update image path.
        if (newImagePath != null && newImagePath.isNotEmpty) {
          await txn.update(
            _songTableName,
            Map.fromEntries([MapEntry(_imagePathColumnName, newImagePath)]),
            where: "$_songIdColumnName = ?",
            whereArgs: [oldSong.id],
          );
          newSong = newSong.copyWith(imagePath: newImagePath);
        }
      });

      return Success(newSong);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Inserts a playlist titled [playlistTitle] in the database.
  ///
  /// Returns the playlist id.
  Future<Result<int>> insertPlaylist(String playlistTitle) async {
    try {
      final playlistId = await _database!.insert(_playlistTableName, {
        _playlistTitleColumnName: playlistTitle,
      });
      return Success(playlistId);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Inserts rows in the playlist track table with the specified [playlistId] and [songIds].
  Future<Result<void>> insertPlaylistTracks(
    int playlistId,
    List<int> songIds,
  ) async {
    try {
      await _database!.transaction((txn) async {
        final batch = txn.batch();
        for (final songId in songIds) {
          batch.insert(_playlistTrackTableName, {
            _playlistIdColumnName: playlistId,
            _songIdColumnName: songId,
          });
        }
        await batch.commit();
      });
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Deletes rows from the playlist table identified by [playlistIds].
  Future<Result<void>> deletePlaylists(List<int> playlistIds) async {
    try {
      await _database!.transaction((txn) async {
        final batch = txn.batch();

        for (final playlistId in playlistIds) {
          batch.delete(
            _playlistTableName,
            where: "$_playlistIdColumnName = ?",
            whereArgs: [playlistId],
          );
        }
        final rowsDeleted = await batch.commit();
        if (rowsDeleted.length != playlistIds.length) {
          return Failure(Exception("One or more playlists was not found"));
        }
      });
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Deletes rows from the playlist track table identified by [playlistId] and [songIds].
  Future<Result<void>> deletePlaylistTracks(
    int playlistId,
    List<int> songIds,
  ) async {
    try {
      await _database!.transaction((txn) async {
        final batch = txn.batch();
        for (final songId in songIds) {
          batch.delete(
            _playlistTrackTableName,
            where: "$_playlistIdColumnName = ? AND $_songIdColumnName = ?",
            whereArgs: [playlistId, songId],
          );
        }
        final rowsDeleted = await batch.commit();
        if (rowsDeleted.length != songIds.length) {
          return Failure(
            Exception(
              "One or more tracks were not found in the playlist with id $playlistId",
            ),
          );
        }
      });
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Saves the [queue] to the database, raplacing whatever was saved before it.
  Future<Result<void>> saveQueue(SongQueue queue) async {
    try {
      await _database!.transaction((txn) async {
        (await deleteQueue(executor: txn)).getOrThrow();
        final batch = txn.batch();
        for (final id in queue.songIds) {
          batch.insert(_queuedSongTableName, {
            _songIdColumnName: id,
            _positionColumnName: queue.songIds.indexOf(id),
            _currentSongColumnName:
                (queue.songIds.indexOf(id) == queue.currentSongIndex) ? 1 : 0,
          });
        }
        batch.commit();
      });
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /*
  Future<Result<void>> addSongsToQueue(List<int> songIds) async {
    try {
      await _database!.transaction((txn) async {
        final queue = await txn.query(
          _queuedSongTableName,
          columns: [_songIdColumnName],
        );
        final batch = txn.batch();

        for (final id in songIds) {
          batch.insert(_queuedSongTableName, {
            _songIdColumnName: id,
            _positionColumnName: songIds.indexOf(id) + queue.length,
            _currentSongColumnName: (queue.isEmpty && songIds.indexOf(id) == 0)
                ? 1
                : 0,
          });
        }
        batch.commit();
      });
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
  */

  /// Empties the queue table.
  Future<Result<void>> deleteQueue({DatabaseExecutor? executor}) async {
    try {
      DatabaseExecutor? db = (executor != null) ? executor : _database;
      await db!.delete(_queuedSongTableName);
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  // Future<void> _deleteDatabase() async {
  //   if (_database == null) {
  //     await open();
  //   }
  //   databaseFactory.deleteDatabase(_database!.path);
  // }

  Future<Result<List<String>>> getSongPaths() async {
    try {
      final list = (await _database!.query(
        _songTableName,
        columns: [_pathColumnName],
      )).map((e) => e[_pathColumnName] as String).toList();
      return Success(list);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<void>> insertKVPair(String key, String value) async {
    try {
      await _database!.insert(_keyValueStoreTableName, {
        _keyColumnName: key,
        _valueColumnName: value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<String>> getValue(String key) async {
    try {
      final queryResult = (await _database!.query(
        _keyValueStoreTableName,
        columns: [_valueColumnName],
        where: "$_keyColumnName = ?",
        whereArgs: [key],
      )).map((e) => e[_valueColumnName] as String).toList();
      if (queryResult.isNotEmpty) {
        final String value = (queryResult.isNotEmpty) ? queryResult.first : "";
        return Success(value);
      } else {
        return Failure(Exception("No value found for the key $key"));
      }
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<Result<bool>> isImagePathPresent(String imagePath) async {
    try {
      final queryResult = (await _database!.rawQuery(
        "SELECT 1 FROM $_songTableName WHERE $_imagePathColumnName = ? LIMIT 1",
        [imagePath],
      ));
      if (queryResult.isNotEmpty) {
        return Success(true);
      } else {
        return Success(false);
      }
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
