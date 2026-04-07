import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'album.freezed.dart';

@freezed
abstract class Album with _$Album {
  const factory Album({
    required int id,
    required String title,
    required UnmodifiableListView<String> albumArtists,
    int? year,
    String? imageId,
  }) = _Album;
}
