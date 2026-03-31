import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';

@freezed
abstract class Song with _$Song {
  const factory Song({
    required int id,
    required String title,
    required String artist,
    required String album,
    String? genre,
    int? year,
    int? bitrate,
    int? trackNumber,
    required String path,
    String? imageId,
  }) = _Song;
}
