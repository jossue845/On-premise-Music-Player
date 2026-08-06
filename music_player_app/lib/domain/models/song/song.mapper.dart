// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'song.dart';

class SongMapper extends ClassMapperBase<Song> {
  SongMapper._();

  static SongMapper? _instance;
  static SongMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SongMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Song';

  static int _$id(Song v) => v.id;
  static const Field<Song, int> _f$id = Field('id', _$id);
  static String _$title(Song v) => v.title;
  static const Field<Song, String> _f$title = Field('title', _$title);
  static UnmodifiableListView<String> _$artists(Song v) => v.artists;
  static const Field<Song, UnmodifiableListView<String>> _f$artists =
      Field('artists', _$artists);
  static String _$album(Song v) => v.album;
  static const Field<Song, String> _f$album = Field('album', _$album);
  static int _$albumId(Song v) => v.albumId;
  static const Field<Song, int> _f$albumId = Field('albumId', _$albumId);
  static String? _$genre(Song v) => v.genre;
  static const Field<Song, String> _f$genre =
      Field('genre', _$genre, opt: true);
  static int? _$year(Song v) => v.year;
  static const Field<Song, int> _f$year = Field('year', _$year, opt: true);
  static int? _$trackNumber(Song v) => v.trackNumber;
  static const Field<Song, int> _f$trackNumber =
      Field('trackNumber', _$trackNumber, opt: true);
  static String _$path(Song v) => v.path;
  static const Field<Song, String> _f$path = Field('path', _$path);
  static String? _$imagePath(Song v) => v.imagePath;
  static const Field<Song, String> _f$imagePath =
      Field('imagePath', _$imagePath, opt: true);
  static bool _$favorite(Song v) => v.favorite;
  static const Field<Song, bool> _f$favorite = Field('favorite', _$favorite);
  static int _$playCount(Song v) => v.playCount;
  static const Field<Song, int> _f$playCount =
      Field('playCount', _$playCount, opt: true, def: 0);
  static String? _$lyrics(Song v) => v.lyrics;
  static const Field<Song, String> _f$lyrics =
      Field('lyrics', _$lyrics, opt: true);

  @override
  final MappableFields<Song> fields = const {
    #id: _f$id,
    #title: _f$title,
    #artists: _f$artists,
    #album: _f$album,
    #albumId: _f$albumId,
    #genre: _f$genre,
    #year: _f$year,
    #trackNumber: _f$trackNumber,
    #path: _f$path,
    #imagePath: _f$imagePath,
    #favorite: _f$favorite,
    #playCount: _f$playCount,
    #lyrics: _f$lyrics,
  };

  static Song _instantiate(DecodingData data) {
    return Song(
        id: data.dec(_f$id),
        title: data.dec(_f$title),
        artists: data.dec(_f$artists),
        album: data.dec(_f$album),
        albumId: data.dec(_f$albumId),
        genre: data.dec(_f$genre),
        year: data.dec(_f$year),
        trackNumber: data.dec(_f$trackNumber),
        path: data.dec(_f$path),
        imagePath: data.dec(_f$imagePath),
        favorite: data.dec(_f$favorite),
        playCount: data.dec(_f$playCount),
        lyrics: data.dec(_f$lyrics));
  }

  @override
  final Function instantiate = _instantiate;

  static Song fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Song>(map);
  }

  static Song fromJson(String json) {
    return ensureInitialized().decodeJson<Song>(json);
  }
}

mixin SongMappable {
  String toJson() {
    return SongMapper.ensureInitialized().encodeJson<Song>(this as Song);
  }

  Map<String, dynamic> toMap() {
    return SongMapper.ensureInitialized().encodeMap<Song>(this as Song);
  }

  SongCopyWith<Song, Song, Song> get copyWith =>
      _SongCopyWithImpl<Song, Song>(this as Song, $identity, $identity);
  @override
  String toString() {
    return SongMapper.ensureInitialized().stringifyValue(this as Song);
  }

  @override
  bool operator ==(Object other) {
    return SongMapper.ensureInitialized().equalsValue(this as Song, other);
  }

  @override
  int get hashCode {
    return SongMapper.ensureInitialized().hashValue(this as Song);
  }
}

extension SongValueCopy<$R, $Out> on ObjectCopyWith<$R, Song, $Out> {
  SongCopyWith<$R, Song, $Out> get $asSong =>
      $base.as((v, t, t2) => _SongCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SongCopyWith<$R, $In extends Song, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {int? id,
      String? title,
      UnmodifiableListView<String>? artists,
      String? album,
      int? albumId,
      String? genre,
      int? year,
      int? trackNumber,
      String? path,
      String? imagePath,
      bool? favorite,
      int? playCount,
      String? lyrics});
  SongCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SongCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Song, $Out>
    implements SongCopyWith<$R, Song, $Out> {
  _SongCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Song> $mapper = SongMapper.ensureInitialized();
  @override
  $R call(
          {int? id,
          String? title,
          UnmodifiableListView<String>? artists,
          String? album,
          int? albumId,
          Object? genre = $none,
          Object? year = $none,
          Object? trackNumber = $none,
          String? path,
          Object? imagePath = $none,
          bool? favorite,
          int? playCount,
          Object? lyrics = $none}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (title != null) #title: title,
        if (artists != null) #artists: artists,
        if (album != null) #album: album,
        if (albumId != null) #albumId: albumId,
        if (genre != $none) #genre: genre,
        if (year != $none) #year: year,
        if (trackNumber != $none) #trackNumber: trackNumber,
        if (path != null) #path: path,
        if (imagePath != $none) #imagePath: imagePath,
        if (favorite != null) #favorite: favorite,
        if (playCount != null) #playCount: playCount,
        if (lyrics != $none) #lyrics: lyrics
      }));
  @override
  Song $make(CopyWithData data) => Song(
      id: data.get(#id, or: $value.id),
      title: data.get(#title, or: $value.title),
      artists: data.get(#artists, or: $value.artists),
      album: data.get(#album, or: $value.album),
      albumId: data.get(#albumId, or: $value.albumId),
      genre: data.get(#genre, or: $value.genre),
      year: data.get(#year, or: $value.year),
      trackNumber: data.get(#trackNumber, or: $value.trackNumber),
      path: data.get(#path, or: $value.path),
      imagePath: data.get(#imagePath, or: $value.imagePath),
      favorite: data.get(#favorite, or: $value.favorite),
      playCount: data.get(#playCount, or: $value.playCount),
      lyrics: data.get(#lyrics, or: $value.lyrics));

  @override
  SongCopyWith<$R2, Song, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SongCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
