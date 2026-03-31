import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'album.freezed.dart';

@freezed
abstract class Album with _$Album {
  const factory Album({
    required String title,
    String? albumArtist,
    String? date,
    String? imageId,
    required UnmodifiableListView<int> songIds,
  }) = _Album;
}
