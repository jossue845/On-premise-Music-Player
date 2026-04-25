// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'artist.dart';

class ArtistMapper extends ClassMapperBase<Artist> {
  ArtistMapper._();

  static ArtistMapper? _instance;
  static ArtistMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ArtistMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Artist';

  static int _$id(Artist v) => v.id;
  static const Field<Artist, int> _f$id = Field('id', _$id);
  static String _$name(Artist v) => v.name;
  static const Field<Artist, String> _f$name = Field('name', _$name);

  @override
  final MappableFields<Artist> fields = const {
    #id: _f$id,
    #name: _f$name,
  };

  static Artist _instantiate(DecodingData data) {
    return Artist(id: data.dec(_f$id), name: data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static Artist fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Artist>(map);
  }

  static Artist fromJson(String json) {
    return ensureInitialized().decodeJson<Artist>(json);
  }
}

mixin ArtistMappable {
  String toJson() {
    return ArtistMapper.ensureInitialized().encodeJson<Artist>(this as Artist);
  }

  Map<String, dynamic> toMap() {
    return ArtistMapper.ensureInitialized().encodeMap<Artist>(this as Artist);
  }

  ArtistCopyWith<Artist, Artist, Artist> get copyWith =>
      _ArtistCopyWithImpl<Artist, Artist>(this as Artist, $identity, $identity);
  @override
  String toString() {
    return ArtistMapper.ensureInitialized().stringifyValue(this as Artist);
  }

  @override
  bool operator ==(Object other) {
    return ArtistMapper.ensureInitialized().equalsValue(this as Artist, other);
  }

  @override
  int get hashCode {
    return ArtistMapper.ensureInitialized().hashValue(this as Artist);
  }
}

extension ArtistValueCopy<$R, $Out> on ObjectCopyWith<$R, Artist, $Out> {
  ArtistCopyWith<$R, Artist, $Out> get $asArtist =>
      $base.as((v, t, t2) => _ArtistCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ArtistCopyWith<$R, $In extends Artist, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? id, String? name});
  ArtistCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ArtistCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Artist, $Out>
    implements ArtistCopyWith<$R, Artist, $Out> {
  _ArtistCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Artist> $mapper = ArtistMapper.ensureInitialized();
  @override
  $R call({int? id, String? name}) => $apply(FieldCopyWithData(
      {if (id != null) #id: id, if (name != null) #name: name}));
  @override
  Artist $make(CopyWithData data) => Artist(
      id: data.get(#id, or: $value.id), name: data.get(#name, or: $value.name));

  @override
  ArtistCopyWith<$R2, Artist, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ArtistCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
