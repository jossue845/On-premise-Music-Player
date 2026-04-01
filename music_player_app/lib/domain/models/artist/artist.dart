import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'artist.freezed.dart';

@freezed
abstract class Artist with _$Artist {
  const factory Artist({
    required int id,
    required String name,
    required UnmodifiableListView<int> songIds,
  }) = _Artist;
}
