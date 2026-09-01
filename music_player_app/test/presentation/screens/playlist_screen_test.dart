import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/presentation/screens/playlist_screen.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/repositories/playlist_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/domain/models/playlist/playlist.dart';

class MockSongRepository extends Mock implements SongRepository {}
class MockPlaylistRepository extends Mock implements PlaylistRepository {}

// Fake models for mock data returns
class MockPlaylist extends Mock implements Playlist {}

Song _buildSong(int id, bool isFav) {
  return Song(
    id: id,
    title: 'Test Song',
    artists: UnmodifiableListView(['Test Artist']),
    album: 'Test Album',
    albumId: 1,
    path: '/path/$id.mp3',
    favorite: isFav,
    playCount: 0,
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
      home: PlaylistScreen(
        testSongRepository: mockSongRepo,
        testPlaylistRepository: mockPlaylistRepo,
      ),
    );
  }

  group('PlaylistScreen Widget Tests', () {
    testWidgets('Loads favorites count and renders custom playlists', (tester) async {
      // 1 favorite, 1 non-favorite
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(1, true),
        _buildSong(2, false),
      ]));

      // 1 custom playlist
      final mockPlaylist = MockPlaylist();
      when(() => mockPlaylist.id).thenReturn(99);
      when(() => mockPlaylist.title).thenReturn('Driving Mix');
      
      when(() => mockPlaylistRepo.getPlaylists()).thenAnswer((_) async => Success([mockPlaylist]));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Verify favorites card displays '1 songs'
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('1 songs'), findsOneWidget);

      // Verify custom playlist is rendered
      expect(find.text('My Playlists'), findsOneWidget);
      expect(find.text('Driving Mix'), findsOneWidget);
    });

    testWidgets('Tapping add button opens dialog and creates playlist', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => const Success([]));
      when(() => mockPlaylistRepo.getPlaylists()).thenAnswer((_) async => const Success([]));
      when(() => mockPlaylistRepo.createPlaylist(any())).thenAnswer((_) async => const Success(1));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Tap the + button in AppBar
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('New Playlist'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter text and tap Create
      await tester.enterText(find.byType(TextField), 'Gym Vibes');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify repository method was called
      verify(() => mockPlaylistRepo.createPlaylist('Gym Vibes')).called(1);
    });

    testWidgets('Deleting a playlist triggers repository call', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => const Success([]));
      
      final mockPlaylist = MockPlaylist();
      when(() => mockPlaylist.id).thenReturn(77);
      when(() => mockPlaylist.title).thenReturn('To Delete');
      
      // Return a list with the playlist on first load, then empty list on refresh
      int callCount = 0;
      when(() => mockPlaylistRepo.getPlaylists()).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? Success([mockPlaylist]) : const Success([]);
      });

      when(() => mockPlaylistRepo.deletePlaylists([77])).thenAnswer((_) async => const Success(unit));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Open popup menu for the custom playlist
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();

      // Tap Delete playlist
      await tester.tap(find.text('Delete playlist'));
      await tester.pumpAndSettle();

      // Verify repository was commanded to delete the specific ID
      verify(() => mockPlaylistRepo.deletePlaylists([77])).called(1);
    });
  });
}