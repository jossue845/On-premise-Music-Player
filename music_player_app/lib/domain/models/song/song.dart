import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';

@freezed
abstract class Song with _$Song {
  const factory Song({
    required int id,
    required String title,
    required UnmodifiableListView<String> artists,
    required String album,
    required int albumId,
    String? genre,
    int? year,
    int? bitrate,
    int? trackNumber,
    required String path,
    String? imagePath,
  }) = _Song;
}
