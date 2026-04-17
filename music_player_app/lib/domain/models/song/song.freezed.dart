// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Song implements DiagnosticableTreeMixin {

 int get id; String get title; UnmodifiableListView<String> get artists; String get album; int get albumId; String? get genre; int? get year; int? get bitrate; int? get trackNumber; String get path; String? get imagePath;
/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongCopyWith<Song> get copyWith => _$SongCopyWithImpl<Song>(this as Song, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Song'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('artists', artists))..add(DiagnosticsProperty('album', album))..add(DiagnosticsProperty('albumId', albumId))..add(DiagnosticsProperty('genre', genre))..add(DiagnosticsProperty('year', year))..add(DiagnosticsProperty('bitrate', bitrate))..add(DiagnosticsProperty('trackNumber', trackNumber))..add(DiagnosticsProperty('path', path))..add(DiagnosticsProperty('imagePath', imagePath));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Song&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.artists, artists)&&(identical(other.album, album) || other.album == album)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.year, year) || other.year == year)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.trackNumber, trackNumber) || other.trackNumber == trackNumber)&&(identical(other.path, path) || other.path == path)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(artists),album,albumId,genre,year,bitrate,trackNumber,path,imagePath);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Song(id: $id, title: $title, artists: $artists, album: $album, albumId: $albumId, genre: $genre, year: $year, bitrate: $bitrate, trackNumber: $trackNumber, path: $path, imagePath: $imagePath)';
}


}

/// @nodoc
abstract mixin class $SongCopyWith<$Res>  {
  factory $SongCopyWith(Song value, $Res Function(Song) _then) = _$SongCopyWithImpl;
@useResult
$Res call({
 int id, String title, UnmodifiableListView<String> artists, String album, int albumId, String? genre, int? year, int? bitrate, int? trackNumber, String path, String? imagePath
});




}
/// @nodoc
class _$SongCopyWithImpl<$Res>
    implements $SongCopyWith<$Res> {
  _$SongCopyWithImpl(this._self, this._then);

  final Song _self;
  final $Res Function(Song) _then;

/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? artists = null,Object? album = null,Object? albumId = null,Object? genre = freezed,Object? year = freezed,Object? bitrate = freezed,Object? trackNumber = freezed,Object? path = null,Object? imagePath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as UnmodifiableListView<String>,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,albumId: null == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as int,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as int?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Song].
extension SongPatterns on Song {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Song value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Song value)  $default,){
final _that = this;
switch (_that) {
case _Song():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Song value)?  $default,){
final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  UnmodifiableListView<String> artists,  String album,  int albumId,  String? genre,  int? year,  int? bitrate,  int? trackNumber,  String path,  String? imagePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that.id,_that.title,_that.artists,_that.album,_that.albumId,_that.genre,_that.year,_that.bitrate,_that.trackNumber,_that.path,_that.imagePath);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  UnmodifiableListView<String> artists,  String album,  int albumId,  String? genre,  int? year,  int? bitrate,  int? trackNumber,  String path,  String? imagePath)  $default,) {final _that = this;
switch (_that) {
case _Song():
return $default(_that.id,_that.title,_that.artists,_that.album,_that.albumId,_that.genre,_that.year,_that.bitrate,_that.trackNumber,_that.path,_that.imagePath);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  UnmodifiableListView<String> artists,  String album,  int albumId,  String? genre,  int? year,  int? bitrate,  int? trackNumber,  String path,  String? imagePath)?  $default,) {final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that.id,_that.title,_that.artists,_that.album,_that.albumId,_that.genre,_that.year,_that.bitrate,_that.trackNumber,_that.path,_that.imagePath);case _:
  return null;

}
}

}

/// @nodoc


class _Song with DiagnosticableTreeMixin implements Song {
  const _Song({required this.id, required this.title, required this.artists, required this.album, required this.albumId, this.genre, this.year, this.bitrate, this.trackNumber, required this.path, this.imagePath});
  

@override final  int id;
@override final  String title;
@override final  UnmodifiableListView<String> artists;
@override final  String album;
@override final  int albumId;
@override final  String? genre;
@override final  int? year;
@override final  int? bitrate;
@override final  int? trackNumber;
@override final  String path;
@override final  String? imagePath;

/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongCopyWith<_Song> get copyWith => __$SongCopyWithImpl<_Song>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Song'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('artists', artists))..add(DiagnosticsProperty('album', album))..add(DiagnosticsProperty('albumId', albumId))..add(DiagnosticsProperty('genre', genre))..add(DiagnosticsProperty('year', year))..add(DiagnosticsProperty('bitrate', bitrate))..add(DiagnosticsProperty('trackNumber', trackNumber))..add(DiagnosticsProperty('path', path))..add(DiagnosticsProperty('imagePath', imagePath));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Song&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.artists, artists)&&(identical(other.album, album) || other.album == album)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.year, year) || other.year == year)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.trackNumber, trackNumber) || other.trackNumber == trackNumber)&&(identical(other.path, path) || other.path == path)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(artists),album,albumId,genre,year,bitrate,trackNumber,path,imagePath);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Song(id: $id, title: $title, artists: $artists, album: $album, albumId: $albumId, genre: $genre, year: $year, bitrate: $bitrate, trackNumber: $trackNumber, path: $path, imagePath: $imagePath)';
}


}

/// @nodoc
abstract mixin class _$SongCopyWith<$Res> implements $SongCopyWith<$Res> {
  factory _$SongCopyWith(_Song value, $Res Function(_Song) _then) = __$SongCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, UnmodifiableListView<String> artists, String album, int albumId, String? genre, int? year, int? bitrate, int? trackNumber, String path, String? imagePath
});




}
/// @nodoc
class __$SongCopyWithImpl<$Res>
    implements _$SongCopyWith<$Res> {
  __$SongCopyWithImpl(this._self, this._then);

  final _Song _self;
  final $Res Function(_Song) _then;

/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? artists = null,Object? album = null,Object? albumId = null,Object? genre = freezed,Object? year = freezed,Object? bitrate = freezed,Object? trackNumber = freezed,Object? path = null,Object? imagePath = freezed,}) {
  return _then(_Song(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as UnmodifiableListView<String>,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,albumId: null == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as int,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as int?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
