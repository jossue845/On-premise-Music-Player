import 'dart:collection';

import 'package:dart_mappable/dart_mappable.dart';

part 'album.mapper.dart';

@MappableClass()
class Album with AlbumMappable {
  final int id;
  final String title;
  final UnmodifiableListView<String> albumArtists;
  final int? year;
  final String? imagePath;

  Album({
    required this.id,
    required this.title,
    required this.albumArtists,
    this.year,
    this.imagePath,
  });
}
