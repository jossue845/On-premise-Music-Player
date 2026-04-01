import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'queue.freezed.dart';

@freezed
abstract class Queue with _$Queue {
  const factory Queue({
    required UnmodifiableListView<int> songIds,
    required currentSongIndex,
  }) = _Queue;
}
