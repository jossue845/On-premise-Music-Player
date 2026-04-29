import 'dart:collection';

import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/queue/song_queue.dart';
import 'package:music_player_app/domain/models/song/song.dart';
import 'package:result_dart/result_dart.dart';

class QueueRepository {
  final DatabaseService _database;

  QueueRepository({required DatabaseService database}) : _database = database;

  /// Returns the queue.
  Future<Result<SongQueue>> getQueue() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getQueue();
  }

  /// Saves the [queue].
  Future<Result<void>> saveQueue(SongQueue queue) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.saveQueue(queue);
  }

  /// Shuffles [queue] and returns it.
  ///
  /// If [keepCurrentSongAsFirst] is true, the returned [SongQueue] will have the [queue]'s current song as its first and current song.
  Result<SongQueue> shuffle({
    required SongQueue queue,
    bool keepCurrentSongAsFirst = false,
  }) {
    try {
      if (queue.songIds.isEmpty) {
        return Success(queue);
      }

      List<int> newSongList = List.from(queue.songIds);

      if (keepCurrentSongAsFirst) {
        int songId = newSongList.removeAt(queue.currentSongIndex);
        newSongList.shuffle();
        newSongList.insert(0, songId);
      } else {
        newSongList.shuffle();
      }
      return Success(
        SongQueue(
          songIds: UnmodifiableListView(newSongList),
          currentSongIndex: 0,
        ),
      );
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Adds [songIds] to the [queue] and returns it.
  Result<SongQueue> addSongs(SongQueue queue, List<int> songIds) {
    try {
      List<int> newSongList = List.of(queue.songIds);
      newSongList.addAll(songIds);
      return Success(
        queue.copyWith(songIds: UnmodifiableListView(newSongList)),
      );
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// Removes the song at [index] in the [queue]'s song list and returns it.
  ///
  /// If the current song is removed, the next song in queue will be set as current; if it also was the last song, the new last song is set as current.
  ///
  /// If [index] is out of bounds, its value is clamped.
  Result<SongQueue> removeSong(SongQueue queue, int index) {
    try {
      List<int> newSongList = List.of(queue.songIds);
      int newCurrentIndex = queue.currentSongIndex;

      index = index.clamp(0, queue.songIds.length - 1);
      newSongList.removeAt(index);

      if (index == queue.currentSongIndex) {
        newCurrentIndex = newCurrentIndex + 1;
        newCurrentIndex = newCurrentIndex.clamp(0, newSongList.length - 1);
      }

      return Success(
        SongQueue(
          songIds: UnmodifiableListView(newSongList),
          currentSongIndex: newCurrentIndex,
        ),
      );
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
