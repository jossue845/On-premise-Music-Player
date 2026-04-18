import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'song_queue.freezed.dart';

@freezed
abstract class SongQueue with _$SongQueue {
  const factory SongQueue._int({
    required UnmodifiableListView<int> songIds,
    required currentSongIndex,
  }) = _SongQueue;

  factory SongQueue({
    required UnmodifiableListView<int> songIds,
    required currentSongIndex,
  }) {
    int idx;
    if (currentSongIndex < 0) {
      idx = 0;
    } else if (currentSongIndex >= songIds.length) {
      if (songIds.isEmpty) {
        idx = 0;
      } else {
        idx = songIds.length - 1;
      }
    } else {
      idx = currentSongIndex;
    }
    return SongQueue._int(songIds: songIds, currentSongIndex: idx);
  }
}
