import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:music_player_app/presentation/screens/artists_screen.dart'; 
import 'package:music_player_app/presentation/screens/sartist_screen.dart';

class MockSongRepository extends Mock implements SongRepository {}

Song _buildSong({required int id, required String title, required List<String> artists}) {
  return Song(
    id: id,
    title: title,
    artists: UnmodifiableListView(artists),
    album: 'Test Album',
    albumId: 1,
    path: '/fake/path/$id.mp3',
    favorite: false,
    playCount: 0,
  );
}

void main() {
  late MockSongRepository mockSongRepo;

  setUp(() {
    mockSongRepo = MockSongRepository();
  });

  Widget buildTestable() {
    return MaterialApp(
      home: ArtistsScreen(
        testSongRepository: mockSongRepo,
      ),
    );
  }

  group('ArtistsScreen Widget Tests', () {
    
    testWidgets('shows empty state when no artists are returned', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => const Success([]));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      expect(find.text('No artists found. Scan for music in Settings.'), findsOneWidget);
    });

    testWidgets('groups duplicate artists and sorts them alphabetically', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(id: 1, title: 'Song 1', artists: ['Zebra']),
        _buildSong(id: 2, title: 'Song 2', artists: ['Zebra']), // Duplicate artist
        _buildSong(id: 3, title: 'Song 3', artists: ['Apple']),
      ]));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Ensure duplicates are grouped (we expect exactly 2 artist cards, not 3)
      expect(find.byType(Card), findsNWidgets(2));

      // Extract the text to verify alphabetical sorting
      final renderedTexts = tester.widgetList<Text>(find.byType(Text))
          .map((textWidget) => textWidget.data)
          .where((text) => text == 'Apple' || text == 'Zebra')
          .toList();

      expect(renderedTexts.first, 'Apple');
      expect(renderedTexts.last, 'Zebra');
    });

    testWidgets('tapping an artist card navigates to ArtistDetailScreen', (tester) async {
      when(() => mockSongRepo.getSongs()).thenAnswer((_) async => Success([
        _buildSong(id: 1, title: 'Song', artists: ['Queen']),
      ]));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      final artistCard = find.text('Queen');
      expect(artistCard, findsOneWidget);

      await tester.tap(artistCard);
      await tester.pumpAndSettle();

      expect(find.byType(ArtistDetailScreen), findsOneWidget);
    });
  });
}