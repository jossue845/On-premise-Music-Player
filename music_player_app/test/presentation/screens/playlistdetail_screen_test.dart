import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/presentation/screens/playlistdetail_screen.dart';
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

  setUp(() {
    mockDb = MockDatabaseService();
    mockSongRepo = MockSongRepository();
    mockPlaylistRepo = MockPlaylistRepository();
  });

  Widget buildTestable({
    required String title,
    int? playlistId,
    bool isFavorites = false,
  }) {
    return MaterialApp(
      home: PlaylistDetailScreen(
        playlistTitle: title,
        initialIsPinned: false,
        playlistId: playlistId,
        isFavoritesPlaylist: isFavorites,
        testDatabaseService: mockDb,
        testSongRepository: mockSongRepo,
        testPlaylistRepository: mockPlaylistRepo,
      ),
    );
  }

  group('PlaylistDetailScreen Widget Tests', () {
    
    testWidgets('Loads and renders songs for a custom playlist', (tester) async {
      when(() => mockSongRepo.getSongs(playlistId: 42)).thenAnswer((_) async => Success([
        _buildSong(1, 'Rock Anthem', false),
      ]));

      await tester.pumpWidget(buildTestable(title: 'My Custom List', playlistId: 42));
      await tester.pumpAndSettle();

      expect(find.text('My Custom List'), findsOneWidget);
      expect(find.text('Rock Anthem'), findsOneWidget);
    });

    testWidgets('Toggles the pin icon when tapped', (tester) async {
      when(() => mockSongRepo.getSongs(playlistId: 42)).thenAnswer((_) async => const Success([]));

      await tester.pumpWidget(buildTestable(title: 'My Custom List', playlistId: 42));
      await tester.pumpAndSettle();

      // Verify the unpinned icon is present initially
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);

      // Tap the pin button
      await tester.tap(find.byTooltip('Pin Playlist'));
      await tester.pumpAndSettle();

      // Verify it changed to the solid pinned icon
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('Removing a song triggers repository call and reloads', (tester) async {
      int callCount = 0;
      when(() => mockSongRepo.getSongs(playlistId: 42)).thenAnswer((_) async {
        callCount++;
        // Return 1 song on the first call, empty list on the second call (after deletion)
        return callCount == 1 ? Success([_buildSong(1, 'Rock Anthem', false)]) : const Success([]);
      });
      
      when(() => mockPlaylistRepo.removeSongsFromPlaylist(42, [1]))
          .thenAnswer((_) async => const Success(unit));

      await tester.pumpWidget(buildTestable(title: 'My Custom List', playlistId: 42));
      await tester.pumpAndSettle();

      // Open the popup menu for the song
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap "Remove from this playlist"
      await tester.tap(find.text('Remove from this playlist'));
      await tester.pumpAndSettle();

      // Verify the repository was called to remove song ID 1
      verify(() => mockPlaylistRepo.removeSongsFromPlaylist(42, [1])).called(1);
      
      // Verify the UI updated to show empty state
      expect(find.text("No songs in this playlist yet."), findsOneWidget);
    });
  });
}