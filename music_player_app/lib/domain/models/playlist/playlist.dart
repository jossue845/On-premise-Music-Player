import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist.freezed.dart';

@freezed
abstract class Playlist with _$Playlist {
  const factory Playlist({
    required int id,
    required String title,
    String? imageId,
  }) = _Playlist;
}
