import 'package:dart_mappable/dart_mappable.dart';

part 'artist.mapper.dart';

@MappableClass()
class Artist with ArtistMappable {
  final int id;
  final String name;
  Artist({required this.id, required this.name});
}
