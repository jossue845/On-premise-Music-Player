import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_app/domain/models/song/song.dart';

void main() {
  group('Song Model Unit Tests', () {
    
    test('copyWith updates specified fields and retains the rest', () {
      // 1. Arrange: Create a baseline song
      final originalSong = Song(
        id: 1,
        title: 'Original Title',
        artists: UnmodifiableListView(['Original Artist']),
        album: 'Original Album',
        albumId: 1, 
        path: '/path/to/song.mp3',
        favorite: false,
        playCount: 5,
      );

      // 2. Act: Use copyWith to toggle favorite status and add lyrics
      final updatedSong = originalSong.copyWith(
        favorite: true,
        lyrics: '[00:10.00] Testing lyrics',
      );

      // 3. Assert: Verify the targeted fields changed
      expect(updatedSong.favorite, true);
      expect(updatedSong.lyrics, '[00:10.00] Testing lyrics');

      // 4. Assert: Verify the untouched fields remained exactly the same
      expect(updatedSong.id, 1);
      expect(updatedSong.title, 'Original Title');
      expect(updatedSong.artists.first, 'Original Artist');
      expect(updatedSong.albumId, 1); 
      expect(updatedSong.playCount, 5);
      expect(updatedSong.path, '/path/to/song.mp3');
    });

  });
}