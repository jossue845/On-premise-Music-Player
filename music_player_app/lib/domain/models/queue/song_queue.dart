import 'dart:collection';

import 'package:dart_mappable/dart_mappable.dart';

part 'song_queue.mapper.dart';

@MappableClass()
class SongQueue with SongQueueMappable {
  final UnmodifiableListView<int> songIds;
  final int currentSongIndex;

  SongQueue({
    required UnmodifiableListView<int> songIds,
    required int currentSongIndex,
  }) : this.songIds = songIds,
       this.currentSongIndex = currentSongIndex
           .clamp(0, songIds.length - 1)
           .toInt();
}
