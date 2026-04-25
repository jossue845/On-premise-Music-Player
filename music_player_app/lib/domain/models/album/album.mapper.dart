// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'album.dart';

class AlbumMapper extends ClassMapperBase<Album> {
  AlbumMapper._();

  static AlbumMapper? _instance;
  static AlbumMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AlbumMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Album';

  static int _$id(Album v) => v.id;
  static const Field<Album, int> _f$id = Field('id', _$id);
  static String _$title(Album v) => v.title;
  static const Field<Album, String> _f$title = Field('title', _$title);
  static UnmodifiableListView<String> _$albumArtists(Album v) => v.albumArtists;
  static const Field<Album, UnmodifiableListView<String>> _f$albumArtists =
      Field('albumArtists', _$albumArtists);
  static int? _$year(Album v) => v.year;
  static const Field<Album, int> _f$year = Field('year', _$year, opt: true);
  static String? _$imagePath(Album v) => v.imagePath;
  static const Field<Album, String> _f$imagePath =
      Field('imagePath', _$imagePath, opt: true);

  @override
  final MappableFields<Album> fields = const {
    #id: _f$id,
    #title: _f$title,
    #albumArtists: _f$albumArtists,
    #year: _f$year,
    #imagePath: _f$imagePath,
  };

  static Album _instantiate(DecodingData data) {
    return Album(
        id: data.dec(_f$id),
        title: data.dec(_f$title),
        albumArtists: data.dec(_f$albumArtists),
        year: data.dec(_f$year),
        imagePath: data.dec(_f$imagePath));
  }

  @override
  final Function instantiate = _instantiate;

  static Album fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Album>(map);
  }

  static Album fromJson(String json) {
    return ensureInitialized().decodeJson<Album>(json);
  }
}

mixin AlbumMappable {
  String toJson() {
    return AlbumMapper.ensureInitialized().encodeJson<Album>(this as Album);
  }

  Map<String, dynamic> toMap() {
    return AlbumMapper.ensureInitialized().encodeMap<Album>(this as Album);
  }

  AlbumCopyWith<Album, Album, Album> get copyWith =>
      _AlbumCopyWithImpl<Album, Album>(this as Album, $identity, $identity);
  @override
  String toString() {
    return AlbumMapper.ensureInitialized().stringifyValue(this as Album);
  }

  @override
  bool operator ==(Object other) {
    return AlbumMapper.ensureInitialized().equalsValue(this as Album, other);
  }

  @override
  int get hashCode {
    return AlbumMapper.ensureInitialized().hashValue(this as Album);
  }
}

extension AlbumValueCopy<$R, $Out> on ObjectCopyWith<$R, Album, $Out> {
  AlbumCopyWith<$R, Album, $Out> get $asAlbum =>
      $base.as((v, t, t2) => _AlbumCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AlbumCopyWith<$R, $In extends Album, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {int? id,
      String? title,
      UnmodifiableListView<String>? albumArtists,
      int? year,
      String? imagePath});
  AlbumCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AlbumCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Album, $Out>
    implements AlbumCopyWith<$R, Album, $Out> {
  _AlbumCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Album> $mapper = AlbumMapper.ensureInitialized();
  @override
  $R call(
          {int? id,
          String? title,
          UnmodifiableListView<String>? albumArtists,
          Object? year = $none,
          Object? imagePath = $none}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (title != null) #title: title,
        if (albumArtists != null) #albumArtists: albumArtists,
        if (year != $none) #year: year,
        if (imagePath != $none) #imagePath: imagePath
      }));
  @override
  Album $make(CopyWithData data) => Album(
      id: data.get(#id, or: $value.id),
      title: data.get(#title, or: $value.title),
      albumArtists: data.get(#albumArtists, or: $value.albumArtists),
      year: data.get(#year, or: $value.year),
      imagePath: data.get(#imagePath, or: $value.imagePath));

  @override
  AlbumCopyWith<$R2, Album, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _AlbumCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
