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
      await database.deleteDatabase();
      await database.open();
    });

    test("database opens normally", () async {
      await expectLater(database.open(), completes);
    });

    test("check conflicts on song, artist and album insert", () async {
      await insertSong(database);
      await insertSong(database);

      final songs = await database.getSongs().getOrThrow();
      final albums = await database.getAlbums().getOrThrow();
      print("Songs: $songs");
      print("Albums: $albums");
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
    albumArtistNames: ["Artist 1"],
  );
  print(result.exceptionOrNull());
}
