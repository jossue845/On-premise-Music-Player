import 'dart:async';

import 'package:path/path.dart';
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
  static const String _nameColumnName = "name";

  late Database _database;
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
            CREATE TABLE $_artistTableName($_artistIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_nameColumnName TEXT NOT NULL);
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
            ''');
        },
        version: 1,
      ),
    );
  }
}
