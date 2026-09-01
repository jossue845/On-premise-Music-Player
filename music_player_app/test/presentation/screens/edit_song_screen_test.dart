import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/presentation/screens/edit_song_screen.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/data/services/audiodb_service.dart';
import 'package:music_player_app/domain/models/song/song.dart';

class MockSongRepository extends Mock implements SongRepository {}
class MockAudioDbService extends Mock implements AudioDbService {}
class FakeSong extends Fake implements Song {}

void main() {
  late MockSongRepository mockSongRepo;
  late MockAudioDbService mockAudioDbService;
  late Song dummySong;

  setUpAll(() {
    registerFallbackValue(FakeSong());
  });

  setUp(() {
    mockSongRepo = MockSongRepository();
    mockAudioDbService = MockAudioDbService();

    dummySong = Song(
      id: 1,
      title: 'Old Title',
      artists: UnmodifiableListView(['Old Artist']),
      album: 'Old Album',
      albumId: 1,
      path: '/path/song.mp3',
      favorite: false,
      playCount: 0,
      genre: 'Rock',
      year: 2000,
      trackNumber: 1,
    );
  });

  Widget buildTestable() {
    return MaterialApp(
      home: EditSongScreen(
        song: dummySong,
        testSongRepository: mockSongRepo,
        testAudioDbService: mockAudioDbService,
      ),
    );
  }

  group('EditSongScreen Widget Tests', () {
    
    testWidgets('Populates text fields with existing song data on load', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Verify initial data is present in the text fields
      expect(find.text('Old Title'), findsOneWidget);
      expect(find.text('Old Artist'), findsOneWidget);
      expect(find.text('Old Album'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('2000'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Tapping save calls repository and navigates back', (tester) async {
      when(() => mockSongRepo.editTags(
        oldSong: any(named: 'oldSong'),
        newTitle: any(named: 'newTitle'),
        newSongArtistNames: any(named: 'newSongArtistNames'),
        newAlbumArtistNames: any(named: 'newAlbumArtistNames'),
        newAlbumTitle: any(named: 'newAlbumTitle'),
        newGenre: any(named: 'newGenre'),
        newYear: any(named: 'newYear'),
        newTrackNumber: any(named: 'newTrackNumber'),
      // --- FIX: Return the dummySong instead of unit ---
      )).thenAnswer((_) async => Success(dummySong));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Tap the checkmark icon to save
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Verify the repository method was called
      verify(() => mockSongRepo.editTags(
        oldSong: dummySong,
        newTitle: 'Old Title', 
        newSongArtistNames: ['Old Artist'],
        newAlbumArtistNames: ['Old Artist'],
        newAlbumTitle: 'Old Album',
        newGenre: 'Rock',
        newYear: 2000,
        newTrackNumber: 1,
      )).called(1);
    });

    testWidgets('Tapping auto-fix fills fields with data from AudioDb', (tester) async {
      when(() => mockAudioDbService.searchTrack('Old Title', 'Old Artist'))
          .thenAnswer((_) async => Success({
                'track': [
                  {
                    'strTrack': 'Magic Title',
                    'strArtist': 'Magic Artist',
                    'strAlbum': 'Magic Album',
                    'strGenre': 'Pop'
                  }
                ]
              }));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_fix_high));
      
      // Standard pumps now work perfectly because the queue is actively managed!
      await tester.pump(); 
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 100)); 

      expect(find.text('Magic Title'), findsOneWidget);
      expect(find.text('Magic Artist'), findsOneWidget);
      expect(find.text('Magic Album'), findsOneWidget);
      expect(find.text('Pop'), findsOneWidget);
      
      expect(find.text('Fields auto-filled! Please review and tap Save.'), findsOneWidget);

      await tester.pumpAndSettle();
    });

  });
}