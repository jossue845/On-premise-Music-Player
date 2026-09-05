import 'dart:collection';
import 'dart:io';

import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/domain/models/queue/song_queue.dart';
import 'package:result_dart/result_dart.dart';

class QueueRepository {
  final DatabaseService _database;

  QueueRepository({required DatabaseService database}) : _database = database;

  // Returns the current state of the song queue from the database
  Future<Result<SongQueue>> getQueue() async {
    if (!_database.isOpen()) await _database.open();
    return _database.getQueue();
  }

  // Persists the current queue state to the database
  Future<Result<void>> saveQueue(SongQueue queue) async {
    if (!_database.isOpen()) await _database.open();
    return _database.saveQueue(queue);
  }

  // Shuffles the queue and optionally keeps the currently playing song at the beginning
  Result<SongQueue> shuffle({
    required SongQueue queue,
    bool keepCurrentSongAsFirst = false,
  }) {
    try {
      if (queue.songIds.isEmpty) return Success(queue);

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
      stderr.writeln(e);
      return Failure(Exception("Failed to shuffle queue."));
    }
  }

  // Adds an explicit list of song IDs to the end of the current queue
  Result<SongQueue> addSongs(SongQueue queue, List<int> songIds) {
    try {
      // Fix: Applied manual iteration for the list aggregation
      List<int> newSongList = [];
      
      for (int i = 0; i < queue.songIds.length; i++) {
        newSongList.add(queue.songIds[i]);
      }
      
      for (int j = 0; j < songIds.length; j++) {
        newSongList.add(songIds[j]);
      }
      
      return Success(
        queue.copyWith(songIds: UnmodifiableListView(newSongList)),
      );
    } on Exception catch (e) {
      stderr.writeln(e);
      return Failure(Exception("Failed to add songs to the queue."));
    }
  }

  // Removes the song at the specified index and handles cursor shifting
  Result<SongQueue> removeSong(SongQueue queue, int index) {
    try {
      // Fix: Safety check to prevent operations on an empty queue using explicit booleans
      bool isQueueEmpty = false;
      if (queue.songIds.isEmpty == true) {
        isQueueEmpty = true;
      }
      
      if (isQueueEmpty == true) {
        return Success(queue);
      }

      List<int> newSongList = List.of(queue.songIds);
      int newCurrentIndex = queue.currentSongIndex;

      // Fix: Safe clamp now that we know length is at least 1
      index = index.clamp(0, queue.songIds.length - 1);
      newSongList.removeAt(index);

      // Fix: Safety check to reset safely if the last song was removed
      if (newSongList.isEmpty) {
        return Success(
          SongQueue(
            songIds: UnmodifiableListView([]),
            currentSongIndex: 0,
          ),
        );
      }

      // Fix: Adjust the currently playing index if necessary using explicit assignments
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
      stderr.writeln(e);
      return Failure(Exception("Failed to remove song from queue."));
    }
  }
}