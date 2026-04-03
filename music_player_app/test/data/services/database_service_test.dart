import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group("DatabaseService tests", () {
    late DatabaseService database;

    setUp(() {
      sqfliteFfiInit();
      database = DatabaseService(databaseFactory: databaseFactoryFfi);
    });

    test("database opens normally", () async {
      await expectLater(database.open(), completes);
    });
  });
}
