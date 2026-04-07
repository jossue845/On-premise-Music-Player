import 'dart:async';
import 'dart:collection';

import 'package:music_player_app/domain/models/album/album.dart';
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

  Future<Result<List<Song>>> getSongs() async {
    final Map<int, Song> songs = {};

    try {
      // one different entry for each song, song_artist pair
      final entries = await _database!.rawQuery('''
          SELECT * FROM $_songTableName NATURAL JOIN $_albumTableName NATURAL JOIN $_songArtistTableName NATURAL JOIN $_artistTableName;
        ''');

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
              imageId: entry[_imageIdColumnName] as String,
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

  Future<Result<List<Album>>> getAlbums() async {
    final Map<int, Album> albums = {};
    var albumArtistsEntries;
    var albumInfoEntries;

    try {
      _database!.transaction((txn) async {
        albumArtistsEntries = await txn.rawQuery('''
          SELECT * FROM $_albumTableName NATURAL JOIN $_albumArtistTableName NATURAL JOIN $_artistTableName
            ''');
        albumInfoEntries = await txn.rawQuery('''
          SELECT DISTINCT $_albumIdColumnName $_imageIdColumnName $_yearColumnName FROM $_songTableName
        ''');
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
          artists.add(entry[_artistNameColumnName]);
          albums[albumId] = albums[albumId]!.copyWith(
            albumArtists: UnmodifiableListView(artists),
          );
        }
      }

      // add image and year
      for (final entry in albumInfoEntries) {
        final albumId = entry[_albumIdColumnName] as int;
        albums[albumId] = albums[albumId]!.copyWith(
          year: entry[_yearColumnName] as int?,
          imageId: entry[_imageIdColumnName] as String?,
        );
      }

      return Success(albums.values.toList());
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
