import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';
import 'dart:collection';

import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/domain/models/playlist/playlist.dart'; // adjust to your actual Playlist model path
import 'package:music_player_app/presentation/screens/all_songs_screen.dart';

class MockSongRepository extends Mock implements SongRepository {}
class MockPlaylistRepository extends Mock implements PlaylistRepository {}

Song _buildSong({
  required int id,
  required String title,
  List<String> artists = const ['Test Artist'],
}) {
  return Song(
    id: id,
    title: title,
    artists: UnmodifiableListView(artists),
    album: 'Test Album',
    albumId: 1,
    path: '/fake/path/$id.mp3',
    favorite: false,
  );
}

void main() {
  late MockSongRepository mockSongRepo;
  late MockPlaylistRepository mockPlaylistRepo;

  setUp(() {
    mockSongRepo = MockSongRepository();
    mockPlaylistRepo = MockPlaylistRepository();
  });

  Widget buildTestable() {
    return MaterialApp(
      home: AllSongsScreen(
        songRepository: mockSongRepo,
        playlistRepository: mockPlaylistRepo,
      ),
    );
  }

  group('AllSongsScreen', () {
    testWidgets('shows loading indicator while fetching songs', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer(
        (_) async => Success([]),
      );

      await tester.pumpWidget(buildTestable());

      // Before the microtask completes, spinner should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('shows empty state when no songs are returned', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer(
        (_) async => Success([]),
      );

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      expect(find.text('No songs found.'), findsOneWidget);
      expect(find.text('Tap here to refresh'), findsOneWidget);
    });

    testWidgets('renders a list of songs sorted by title', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer(
        (_) async => Success([
          _buildSong(id: 1, title: 'Zebra Song'),
          _buildSong(id: 2, title: 'Apple Song'),
        ]),
      );

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));

      // 1. Extract all Text widgets on the screen in their rendered order
      final renderedTexts = tester.widgetList<Text>(find.byType(Text))
          .map((textWidget) => textWidget.data)
          .where((text) => text == 'Apple Song' || text == 'Zebra Song')
          .toList();

      // 2. Verify alphabetical sorting by asserting 'Apple Song' is at index 0
      expect(renderedTexts.first, 'Apple Song');
      expect(renderedTexts.last, 'Zebra Song');
    });

    testWidgets('shows error state gracefully on repository failure', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer(
        (_) async => Failure(Exception('DB error')),
      );

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Screen falls through to the empty-state UI on failure (per current logic)
      expect(find.text('No songs found.'), findsOneWidget);
    });

    testWidgets('tapping refresh re-fetches songs', (tester) async {
      var callCount = 0;
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async {
        callCount++;
        return Success([]);
      });

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap here to refresh'));
      await tester.pumpAndSettle();

      expect(callCount, 2); // initial load + manual refresh
    });

    testWidgets('opens "Add to Playlist" dialog from popup menu', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer(
        (_) async => Success([_buildSong(id: 1, title: 'Song A')]),
      );
      when(() => mockPlaylistRepo.getPlaylists()).thenAnswer(
        (_) async => Success([]),
      );

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to Playlist...'));
      await tester.pumpAndSettle();

      expect(find.text('Add to Playlist'), findsOneWidget); // dialog title
      expect(find.text('No custom playlists available. Create one first!'), findsOneWidget);
    });
  });
}