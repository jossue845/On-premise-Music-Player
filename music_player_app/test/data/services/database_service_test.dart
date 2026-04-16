import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group("DatabaseService tests", () {
    late DatabaseService database;

    setUp(() async {
      sqfliteFfiInit();
      database = DatabaseService(databaseFactory: databaseFactoryFfi);
      await deleteAllRows(database);
      await database.open();
    });

    test("", () async {
      await insertSong(database);
      await database.insertSong(
        title: "Song Title",
        path: "/path/",
        albumTitle: "Album Title 1",
        songArtistNames: ["Artist 2"],
        albumArtistNames: ["Artist 2"],
      );

      var artists = await database.getArtists().getOrThrow();

      var songs = await database
          .getAlbums(artistId: artists[0].id)
          .getOrThrow();
      print("Songs: $songs");
      songs = await database.getAlbums(artistId: artists[1].id).getOrThrow();
      print("Songs: $songs");
    });
  });
}

Future<void> insertSong(DatabaseService database) async {
  if (!database.isOpen()) {
    await database.open();
  }

  final result = await database.insertSong(
    title: "Song Title",
    path: "/path/",
    albumTitle: "Album Title",
    songArtistNames: ["Artist 1", "Artist 2"],
    albumArtistNames: ["Artist 1", "Artist 2"],
  );
  if (result.isError()) {
    print(result.exceptionOrNull());
  }
}

Future<void> deleteAllRows(DatabaseService database) async {
  if (!database.isOpen()) {
    await database.open();
  }
  for (final song in await database.getSongs().getOrThrow()) {
    await database.deleteSong(song.id);
  }
}
