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
  });
}
