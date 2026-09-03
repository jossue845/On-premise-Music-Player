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
  final int playCount; 
  final String? lyrics;

  Song({
    required this.id,
    required String title,
    required this.artists,
    required String album,
    required this.albumId,
    this.genre,
    this.year,
    this.trackNumber,
    required String path,
    this.imagePath,
    required this.favorite,
    this.playCount = 0, 
    this.lyrics,
  })  : title = title.trim().isEmpty ? 'Unknown Title' : title,
        album = album.trim().isEmpty ? 'Unknown Album' : album,
        path = path.trim().isEmpty ? '/' : path;

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'artists': artists.join(','), 
      'album': album,
      'albumId': albumId,
      'genre': genre,
      'year': year,
      'trackNumber': trackNumber,
      'path': path,
      'imagePath': imagePath,
      'favorite': favorite ? 1 : 0, 
      'playCount': playCount,
      'lyrics': lyrics,
    };
  }
}