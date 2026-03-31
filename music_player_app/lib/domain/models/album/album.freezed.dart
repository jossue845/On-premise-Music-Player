// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Album implements DiagnosticableTreeMixin {

 String get title; String? get albumArtist; String? get date; String? get imageId; UnmodifiableListView<int> get songIds;
/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumCopyWith<Album> get copyWith => _$AlbumCopyWithImpl<Album>(this as Album, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Album'))
    ..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('albumArtist', albumArtist))..add(DiagnosticsProperty('date', date))..add(DiagnosticsProperty('imageId', imageId))..add(DiagnosticsProperty('songIds', songIds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Album&&(identical(other.title, title) || other.title == title)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.date, date) || other.date == date)&&(identical(other.imageId, imageId) || other.imageId == imageId)&&const DeepCollectionEquality().equals(other.songIds, songIds));
}


@override
int get hashCode => Object.hash(runtimeType,title,albumArtist,date,imageId,const DeepCollectionEquality().hash(songIds));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Album(title: $title, albumArtist: $albumArtist, date: $date, imageId: $imageId, songIds: $songIds)';
}


}

/// @nodoc
abstract mixin class $AlbumCopyWith<$Res>  {
  factory $AlbumCopyWith(Album value, $Res Function(Album) _then) = _$AlbumCopyWithImpl;
@useResult
$Res call({
 String title, String? albumArtist, String? date, String? imageId, UnmodifiableListView<int> songIds
});




}
/// @nodoc
class _$AlbumCopyWithImpl<$Res>
    implements $AlbumCopyWith<$Res> {
  _$AlbumCopyWithImpl(this._self, this._then);

  final Album _self;
  final $Res Function(Album) _then;

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? albumArtist = freezed,Object? date = freezed,Object? imageId = freezed,Object? songIds = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,imageId: freezed == imageId ? _self.imageId : imageId // ignore: cast_nullable_to_non_nullable
as String?,songIds: null == songIds ? _self.songIds : songIds // ignore: cast_nullable_to_non_nullable
as UnmodifiableListView<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [Album].
extension AlbumPatterns on Album {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Album value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Album() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Album value)  $default,){
final _that = this;
switch (_that) {
case _Album():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Album value)?  $default,){
final _that = this;
switch (_that) {
case _Album() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String? albumArtist,  String? date,  String? imageId,  UnmodifiableListView<int> songIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Album() when $default != null:
return $default(_that.title,_that.albumArtist,_that.date,_that.imageId,_that.songIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String? albumArtist,  String? date,  String? imageId,  UnmodifiableListView<int> songIds)  $default,) {final _that = this;
switch (_that) {
case _Album():
return $default(_that.title,_that.albumArtist,_that.date,_that.imageId,_that.songIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String? albumArtist,  String? date,  String? imageId,  UnmodifiableListView<int> songIds)?  $default,) {final _that = this;
switch (_that) {
case _Album() when $default != null:
return $default(_that.title,_that.albumArtist,_that.date,_that.imageId,_that.songIds);case _:
  return null;

}
}

}

/// @nodoc


class _Album with DiagnosticableTreeMixin implements Album {
  const _Album({required this.title, this.albumArtist, this.date, this.imageId, required this.songIds});
  

@override final  String title;
@override final  String? albumArtist;
@override final  String? date;
@override final  String? imageId;
@override final  UnmodifiableListView<int> songIds;

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumCopyWith<_Album> get copyWith => __$AlbumCopyWithImpl<_Album>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Album'))
    ..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('albumArtist', albumArtist))..add(DiagnosticsProperty('date', date))..add(DiagnosticsProperty('imageId', imageId))..add(DiagnosticsProperty('songIds', songIds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Album&&(identical(other.title, title) || other.title == title)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.date, date) || other.date == date)&&(identical(other.imageId, imageId) || other.imageId == imageId)&&const DeepCollectionEquality().equals(other.songIds, songIds));
}


@override
int get hashCode => Object.hash(runtimeType,title,albumArtist,date,imageId,const DeepCollectionEquality().hash(songIds));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Album(title: $title, albumArtist: $albumArtist, date: $date, imageId: $imageId, songIds: $songIds)';
}


}

/// @nodoc
abstract mixin class _$AlbumCopyWith<$Res> implements $AlbumCopyWith<$Res> {
  factory _$AlbumCopyWith(_Album value, $Res Function(_Album) _then) = __$AlbumCopyWithImpl;
@override @useResult
$Res call({
 String title, String? albumArtist, String? date, String? imageId, UnmodifiableListView<int> songIds
});




}
/// @nodoc
class __$AlbumCopyWithImpl<$Res>
    implements _$AlbumCopyWith<$Res> {
  __$AlbumCopyWithImpl(this._self, this._then);

  final _Album _self;
  final $Res Function(_Album) _then;

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? albumArtist = freezed,Object? date = freezed,Object? imageId = freezed,Object? songIds = null,}) {
  return _then(_Album(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,albumArtist: freezed == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,imageId: freezed == imageId ? _self.imageId : imageId // ignore: cast_nullable_to_non_nullable
as String?,songIds: null == songIds ? _self.songIds : songIds // ignore: cast_nullable_to_non_nullable
as UnmodifiableListView<int>,
  ));
}


}

// dart format on
