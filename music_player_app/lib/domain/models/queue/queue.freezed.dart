// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Queue implements DiagnosticableTreeMixin {

 UnmodifiableListView<int> get songIds; dynamic get currentSongIndex;
/// Create a copy of Queue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueCopyWith<Queue> get copyWith => _$QueueCopyWithImpl<Queue>(this as Queue, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Queue'))
    ..add(DiagnosticsProperty('songIds', songIds))..add(DiagnosticsProperty('currentSongIndex', currentSongIndex));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Queue&&const DeepCollectionEquality().equals(other.songIds, songIds)&&const DeepCollectionEquality().equals(other.currentSongIndex, currentSongIndex));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(songIds),const DeepCollectionEquality().hash(currentSongIndex));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Queue(songIds: $songIds, currentSongIndex: $currentSongIndex)';
}


}

/// @nodoc
abstract mixin class $QueueCopyWith<$Res>  {
  factory $QueueCopyWith(Queue value, $Res Function(Queue) _then) = _$QueueCopyWithImpl;
@useResult
$Res call({
 UnmodifiableListView<int> songIds, dynamic currentSongIndex
});




}
/// @nodoc
class _$QueueCopyWithImpl<$Res>
    implements $QueueCopyWith<$Res> {
  _$QueueCopyWithImpl(this._self, this._then);

  final Queue _self;
  final $Res Function(Queue) _then;

/// Create a copy of Queue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? songIds = null,Object? currentSongIndex = freezed,}) {
  return _then(_self.copyWith(
songIds: null == songIds ? _self.songIds : songIds // ignore: cast_nullable_to_non_nullable
as UnmodifiableListView<int>,currentSongIndex: freezed == currentSongIndex ? _self.currentSongIndex : currentSongIndex // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [Queue].
extension QueuePatterns on Queue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Queue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Queue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Queue value)  $default,){
final _that = this;
switch (_that) {
case _Queue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Queue value)?  $default,){
final _that = this;
switch (_that) {
case _Queue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UnmodifiableListView<int> songIds,  dynamic currentSongIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Queue() when $default != null:
return $default(_that.songIds,_that.currentSongIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UnmodifiableListView<int> songIds,  dynamic currentSongIndex)  $default,) {final _that = this;
switch (_that) {
case _Queue():
return $default(_that.songIds,_that.currentSongIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UnmodifiableListView<int> songIds,  dynamic currentSongIndex)?  $default,) {final _that = this;
switch (_that) {
case _Queue() when $default != null:
return $default(_that.songIds,_that.currentSongIndex);case _:
  return null;

}
}

}

/// @nodoc


class _Queue with DiagnosticableTreeMixin implements Queue {
  const _Queue({required this.songIds, required this.currentSongIndex});
  

@override final  UnmodifiableListView<int> songIds;
@override final  dynamic currentSongIndex;

/// Create a copy of Queue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueCopyWith<_Queue> get copyWith => __$QueueCopyWithImpl<_Queue>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Queue'))
    ..add(DiagnosticsProperty('songIds', songIds))..add(DiagnosticsProperty('currentSongIndex', currentSongIndex));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Queue&&const DeepCollectionEquality().equals(other.songIds, songIds)&&const DeepCollectionEquality().equals(other.currentSongIndex, currentSongIndex));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(songIds),const DeepCollectionEquality().hash(currentSongIndex));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Queue(songIds: $songIds, currentSongIndex: $currentSongIndex)';
}


}

/// @nodoc
abstract mixin class _$QueueCopyWith<$Res> implements $QueueCopyWith<$Res> {
  factory _$QueueCopyWith(_Queue value, $Res Function(_Queue) _then) = __$QueueCopyWithImpl;
@override @useResult
$Res call({
 UnmodifiableListView<int> songIds, dynamic currentSongIndex
});




}
/// @nodoc
class __$QueueCopyWithImpl<$Res>
    implements _$QueueCopyWith<$Res> {
  __$QueueCopyWithImpl(this._self, this._then);

  final _Queue _self;
  final $Res Function(_Queue) _then;

/// Create a copy of Queue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? songIds = null,Object? currentSongIndex = freezed,}) {
  return _then(_Queue(
songIds: null == songIds ? _self.songIds : songIds // ignore: cast_nullable_to_non_nullable
as UnmodifiableListView<int>,currentSongIndex: freezed == currentSongIndex ? _self.currentSongIndex : currentSongIndex // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

// dart format on
