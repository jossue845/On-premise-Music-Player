// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'playlist.dart';

class PlaylistMapper extends ClassMapperBase<Playlist> {
  PlaylistMapper._();

  static PlaylistMapper? _instance;
  static PlaylistMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlaylistMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Playlist';

  static int _$id(Playlist v) => v.id;
  static const Field<Playlist, int> _f$id = Field('id', _$id);
  static String _$title(Playlist v) => v.title;
  static const Field<Playlist, String> _f$title = Field('title', _$title);
  static String? _$imageId(Playlist v) => v.imageId;
  static const Field<Playlist, String> _f$imageId =
      Field('imageId', _$imageId, opt: true);

  @override
  final MappableFields<Playlist> fields = const {
    #id: _f$id,
    #title: _f$title,
    #imageId: _f$imageId,
  };

  static Playlist _instantiate(DecodingData data) {
    return Playlist(
        id: data.dec(_f$id),
        title: data.dec(_f$title),
        imageId: data.dec(_f$imageId));
  }

  @override
  final Function instantiate = _instantiate;

  static Playlist fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Playlist>(map);
  }

  static Playlist fromJson(String json) {
    return ensureInitialized().decodeJson<Playlist>(json);
  }
}

mixin PlaylistMappable {
  String toJson() {
    return PlaylistMapper.ensureInitialized()
        .encodeJson<Playlist>(this as Playlist);
  }

  Map<String, dynamic> toMap() {
    return PlaylistMapper.ensureInitialized()
        .encodeMap<Playlist>(this as Playlist);
  }

  PlaylistCopyWith<Playlist, Playlist, Playlist> get copyWith =>
      _PlaylistCopyWithImpl<Playlist, Playlist>(
          this as Playlist, $identity, $identity);
  @override
  String toString() {
    return PlaylistMapper.ensureInitialized().stringifyValue(this as Playlist);
  }

  @override
  bool operator ==(Object other) {
    return PlaylistMapper.ensureInitialized()
        .equalsValue(this as Playlist, other);
  }

  @override
  int get hashCode {
    return PlaylistMapper.ensureInitialized().hashValue(this as Playlist);
  }
}

extension PlaylistValueCopy<$R, $Out> on ObjectCopyWith<$R, Playlist, $Out> {
  PlaylistCopyWith<$R, Playlist, $Out> get $asPlaylist =>
      $base.as((v, t, t2) => _PlaylistCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlaylistCopyWith<$R, $In extends Playlist, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? id, String? title, String? imageId});
  PlaylistCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PlaylistCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Playlist, $Out>
    implements PlaylistCopyWith<$R, Playlist, $Out> {
  _PlaylistCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Playlist> $mapper =
      PlaylistMapper.ensureInitialized();
  @override
  $R call({int? id, String? title, Object? imageId = $none}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (title != null) #title: title,
        if (imageId != $none) #imageId: imageId
      }));
  @override
  Playlist $make(CopyWithData data) => Playlist(
      id: data.get(#id, or: $value.id),
      title: data.get(#title, or: $value.title),
      imageId: data.get(#imageId, or: $value.imageId));

  @override
  PlaylistCopyWith<$R2, Playlist, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _PlaylistCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
