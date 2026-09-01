import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/presentation/screens/manage_playlist_songs_screen.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockSongRepository extends Mock implements SongRepository {}
class MockPlaylistRepository extends Mock implements PlaylistRepository {}

Song _buildSong(int id, String title, bool isFav) {
  return Song(
    id: id,
    title: title,
    artists: UnmodifiableListView(['Test Artist']),
    album: 'Test Album',
    albumId: 1,
    path: '/path/$id.mp3',
    favorite: isFav,
    playCount: 0,
  );
}

void main() {
  late MockDatabaseService mockDb;
  late MockSongRepository mockSongRepo;
  late MockPlaylistRepository mockPlaylistRepo;
  late List<Song> allLibrarySongs;

  setUp(() {
    mockDb = MockDatabaseService();
    mockSongRepo = MockSongRepository();
    mockPlaylistRepo = MockPlaylistRepository();

    allLibrarySongs = [
      _buildSong(1, 'Song A', true),
      _buildSong(2, 'Song B', false),
    ];
  });

  Widget buildTestable({bool isFavorites = false, int? playlistId}) {
    return MaterialApp(
      home: ManagePlaylistSongsScreen(
        playlistTitle: 'Test Playlist',
        playlistId: playlistId,
        isFavoritesPlaylist: isFavorites,
        testDatabaseService: mockDb,
        testSongRepository: mockSongRepo,
        testPlaylistRepository: mockPlaylistRepo,
      ),
    );
  }

  group('ManagePlaylistSongsScreen Widget Tests', () {
    
    testWidgets('Standard Playlist: Loads and correctly checks existing songs', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success(allLibrarySongs));
      // Playlist only contains Song B
      when(() => mockSongRepo.getSongs(playlistId: 99)).thenAnswer((_) async => Success([allLibrarySongs[1]]));

      await tester.pumpWidget(buildTestable(playlistId: 99));
      await tester.pumpAndSettle();

      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsOneWidget);

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes[0].value, false); // Song A is unchecked
      expect(checkboxes[1].value, true);  // Song B is checked
    });

    testWidgets('Standard Playlist: Adding and removing songs calls the repository', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success(allLibrarySongs));
      when(() => mockSongRepo.getSongs(playlistId: 99)).thenAnswer((_) async => Success([allLibrarySongs[1]]));
      
      when(() => mockPlaylistRepo.addSongsToPlaylist(99, [1])).thenAnswer((_) async => const Success(unit));
      when(() => mockPlaylistRepo.removeSongsFromPlaylist(99, [2])).thenAnswer((_) async => const Success(unit));

      await tester.pumpWidget(buildTestable(playlistId: 99));
      await tester.pumpAndSettle();

      // Check Song A (adding it)
      await tester.tap(find.text('Song A'));
      // Uncheck Song B (removing it)
      await tester.tap(find.text('Song B'));
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      verify(() => mockPlaylistRepo.addSongsToPlaylist(99, [1])).called(1);
      verify(() => mockPlaylistRepo.removeSongsFromPlaylist(99, [2])).called(1);
    });

    testWidgets('Favorites Playlist: Properly interacts directly with the database', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success(allLibrarySongs));
      when(() => mockDb.setFavoriteStatus(2, true)).thenAnswer((_) async => const Success(unit));
      when(() => mockDb.setFavoriteStatus(1, false)).thenAnswer((_) async => const Success(unit));

      // Load as a favorites playlist (playlistId is null)
      await tester.pumpWidget(buildTestable(isFavorites: true));
      await tester.pumpAndSettle();

      // Check Song B (adding to favorites)
      await tester.tap(find.text('Song B'));
      // Uncheck Song A (removing from favorites)
      await tester.tap(find.text('Song A'));
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Verify the DatabaseService was directly called instead of the PlaylistRepository
      verify(() => mockDb.setFavoriteStatus(2, true)).called(1);
      verify(() => mockDb.setFavoriteStatus(1, false)).called(1);
      verifyNever(() => mockPlaylistRepo.addSongsToPlaylist(any(), any()));
    });
  });
}