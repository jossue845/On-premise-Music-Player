import 'dart:collection';
import 'package:dart_mappable/dart_mappable.dart';

part 'song.mapper.dart';

@MappableClass()
class Song with SongMappable {
  final int id;
  final String title;
  final UnmodifiableListView<String> artists;
  final String album;
  final int albumId;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final String path;
  final String? imagePath;
  final bool favorite;
  final int playCount; // Tracks how many times the song has been played
  final String? lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artists,
    required this.album,
    required this.albumId,
    this.genre,
    this.year,
    this.trackNumber,
    required this.path,
    this.imagePath,
    required this.favorite,
    this.playCount = 0, // Defaults to 0 in new songs
    this.lyrics,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'artists': artists.join(','), // Flattens List<String> to a single comma-separated String
      'album': album,
      'albumId': albumId,
      'genre': genre,
      'year': year,
      'trackNumber': trackNumber,
      'path': path,
      'imagePath': imagePath,
      'favorite': favorite ? 1 : 0, // Flattens boolean to an integer (SQLite does not have a native boolean type)
      'playCount': playCount,
      'lyrics': lyrics,
    };
  }
}

