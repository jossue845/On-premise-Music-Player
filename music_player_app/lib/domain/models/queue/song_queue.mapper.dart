// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'song_queue.dart';

class SongQueueMapper extends ClassMapperBase<SongQueue> {
  SongQueueMapper._();

  static SongQueueMapper? _instance;
  static SongQueueMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongQueueMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SongQueue';

  static UnmodifiableListView<int> _$songIds(SongQueue v) => v.songIds;
  static const Field<SongQueue, UnmodifiableListView<int>> _f$songIds =
      Field('songIds', _$songIds);
  static int _$currentSongIndex(SongQueue v) => v.currentSongIndex;
  static const Field<SongQueue, int> _f$currentSongIndex =
      Field('currentSongIndex', _$currentSongIndex);

  @override
  final MappableFields<SongQueue> fields = const {
    #songIds: _f$songIds,
    #currentSongIndex: _f$currentSongIndex,
  };

  static SongQueue _instantiate(DecodingData data) {
    return SongQueue(
        songIds: data.dec(_f$songIds),
        currentSongIndex: data.dec(_f$currentSongIndex));
  }

  @override
  final Function instantiate = _instantiate;

  static SongQueue fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SongQueue>(map);
  }

  static SongQueue fromJson(String json) {
    return ensureInitialized().decodeJson<SongQueue>(json);
  }
}

mixin SongQueueMappable {
  String toJson() {
    return SongQueueMapper.ensureInitialized()
        .encodeJson<SongQueue>(this as SongQueue);
  }

  Map<String, dynamic> toMap() {
    return SongQueueMapper.ensureInitialized()
        .encodeMap<SongQueue>(this as SongQueue);
  }

  SongQueueCopyWith<SongQueue, SongQueue, SongQueue> get copyWith =>
      _SongQueueCopyWithImpl<SongQueue, SongQueue>(
          this as SongQueue, $identity, $identity);
  @override
  String toString() {
    return SongQueueMapper.ensureInitialized()
        .stringifyValue(this as SongQueue);
  }

  @override
  bool operator ==(Object other) {
    return SongQueueMapper.ensureInitialized()
        .equalsValue(this as SongQueue, other);
  }

  @override
  int get hashCode {
    return SongQueueMapper.ensureInitialized().hashValue(this as SongQueue);
  }
}

extension SongQueueValueCopy<$R, $Out> on ObjectCopyWith<$R, SongQueue, $Out> {
  SongQueueCopyWith<$R, SongQueue, $Out> get $asSongQueue =>
      $base.as((v, t, t2) => _SongQueueCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SongQueueCopyWith<$R, $In extends SongQueue, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({UnmodifiableListView<int>? songIds, int? currentSongIndex});
  SongQueueCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SongQueueCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SongQueue, $Out>
    implements SongQueueCopyWith<$R, SongQueue, $Out> {
  _SongQueueCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SongQueue> $mapper =
      SongQueueMapper.ensureInitialized();
  @override
  $R call({UnmodifiableListView<int>? songIds, int? currentSongIndex}) =>
      $apply(FieldCopyWithData({
        if (songIds != null) #songIds: songIds,
        if (currentSongIndex != null) #currentSongIndex: currentSongIndex
      }));
  @override
  SongQueue $make(CopyWithData data) => SongQueue(
      songIds: data.get(#songIds, or: $value.songIds),
      currentSongIndex:
          data.get(#currentSongIndex, or: $value.currentSongIndex));

  @override
  SongQueueCopyWith<$R2, SongQueue, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _SongQueueCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
