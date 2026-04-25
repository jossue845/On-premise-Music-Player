import 'package:dart_mappable/dart_mappable.dart';

part 'playlist.mapper.dart';

@MappableClass()
class Playlist with PlaylistMappable {
  final int id;
  final String title;
  final String? imageId;
  Playlist({required this.id, required this.title, this.imageId});
}
