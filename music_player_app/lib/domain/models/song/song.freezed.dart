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

 int get id; String get title; String get artist; String get album; String? get genre; int? get year; int? get month; int? get day; int? get bitrate; int? get trackNumber; String get path; String? get imageId;
/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongCopyWith<Song> get copyWith => _$SongCopyWithImpl<Song>(this as Song, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Song'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('artist', artist))..add(DiagnosticsProperty('album', album))..add(DiagnosticsProperty('genre', genre))..add(DiagnosticsProperty('year', year))..add(DiagnosticsProperty('month', month))..add(DiagnosticsProperty('day', day))..add(DiagnosticsProperty('bitrate', bitrate))..add(DiagnosticsProperty('trackNumber', trackNumber))..add(DiagnosticsProperty('path', path))..add(DiagnosticsProperty('imageId', imageId));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Song&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.day, day) || other.day == day)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.trackNumber, trackNumber) || other.trackNumber == trackNumber)&&(identical(other.path, path) || other.path == path)&&(identical(other.imageId, imageId) || other.imageId == imageId));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,artist,album,genre,year,month,day,bitrate,trackNumber,path,imageId);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Song(id: $id, title: $title, artist: $artist, album: $album, genre: $genre, year: $year, month: $month, day: $day, bitrate: $bitrate, trackNumber: $trackNumber, path: $path, imageId: $imageId)';
}


}

/// @nodoc
abstract mixin class $SongCopyWith<$Res>  {
  factory $SongCopyWith(Song value, $Res Function(Song) _then) = _$SongCopyWithImpl;
@useResult
$Res call({
 int id, String title, String artist, String album, String? genre, int? year, int? month, int? day, int? bitrate, int? trackNumber, String path, String? imageId
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? artist = null,Object? album = null,Object? genre = freezed,Object? year = freezed,Object? month = freezed,Object? day = freezed,Object? bitrate = freezed,Object? trackNumber = freezed,Object? path = null,Object? imageId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,month: freezed == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int?,day: freezed == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as int?,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as int?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,imageId: freezed == imageId ? _self.imageId : imageId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String artist,  String album,  String? genre,  int? year,  int? month,  int? day,  int? bitrate,  int? trackNumber,  String path,  String? imageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that.id,_that.title,_that.artist,_that.album,_that.genre,_that.year,_that.month,_that.day,_that.bitrate,_that.trackNumber,_that.path,_that.imageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String artist,  String album,  String? genre,  int? year,  int? month,  int? day,  int? bitrate,  int? trackNumber,  String path,  String? imageId)  $default,) {final _that = this;
switch (_that) {
case _Song():
return $default(_that.id,_that.title,_that.artist,_that.album,_that.genre,_that.year,_that.month,_that.day,_that.bitrate,_that.trackNumber,_that.path,_that.imageId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String artist,  String album,  String? genre,  int? year,  int? month,  int? day,  int? bitrate,  int? trackNumber,  String path,  String? imageId)?  $default,) {final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that.id,_that.title,_that.artist,_that.album,_that.genre,_that.year,_that.month,_that.day,_that.bitrate,_that.trackNumber,_that.path,_that.imageId);case _:
  return null;

}
}

}

/// @nodoc


class _Song with DiagnosticableTreeMixin implements Song {
  const _Song({required this.id, required this.title, required this.artist, required this.album, this.genre, this.year, this.month, this.day, this.bitrate, this.trackNumber, required this.path, this.imageId});
  

@override final  int id;
@override final  String title;
@override final  String artist;
@override final  String album;
@override final  String? genre;
@override final  int? year;
@override final  int? month;
@override final  int? day;
@override final  int? bitrate;
@override final  int? trackNumber;
@override final  String path;
@override final  String? imageId;

/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongCopyWith<_Song> get copyWith => __$SongCopyWithImpl<_Song>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Song'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('artist', artist))..add(DiagnosticsProperty('album', album))..add(DiagnosticsProperty('genre', genre))..add(DiagnosticsProperty('year', year))..add(DiagnosticsProperty('month', month))..add(DiagnosticsProperty('day', day))..add(DiagnosticsProperty('bitrate', bitrate))..add(DiagnosticsProperty('trackNumber', trackNumber))..add(DiagnosticsProperty('path', path))..add(DiagnosticsProperty('imageId', imageId));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Song&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.day, day) || other.day == day)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.trackNumber, trackNumber) || other.trackNumber == trackNumber)&&(identical(other.path, path) || other.path == path)&&(identical(other.imageId, imageId) || other.imageId == imageId));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,artist,album,genre,year,month,day,bitrate,trackNumber,path,imageId);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Song(id: $id, title: $title, artist: $artist, album: $album, genre: $genre, year: $year, month: $month, day: $day, bitrate: $bitrate, trackNumber: $trackNumber, path: $path, imageId: $imageId)';
}


}

/// @nodoc
abstract mixin class _$SongCopyWith<$Res> implements $SongCopyWith<$Res> {
  factory _$SongCopyWith(_Song value, $Res Function(_Song) _then) = __$SongCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String artist, String album, String? genre, int? year, int? month, int? day, int? bitrate, int? trackNumber, String path, String? imageId
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? artist = null,Object? album = null,Object? genre = freezed,Object? year = freezed,Object? month = freezed,Object? day = freezed,Object? bitrate = freezed,Object? trackNumber = freezed,Object? path = null,Object? imageId = freezed,}) {
  return _then(_Song(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,genre: freezed == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,month: freezed == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int?,day: freezed == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as int?,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as int?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,imageId: freezed == imageId ? _self.imageId : imageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
