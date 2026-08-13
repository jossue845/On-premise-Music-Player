class Scrobble {
  final int? id;
  final String artist;
  final String track;
  final String? album;
  final int timestamp; // Unix timestamp in seconds
  final bool isSynced;

  Scrobble({
    this.id,
    required this.artist,
    required this.track,
    this.album,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'artist': artist,
      'track': track,
      'album': album,
      'timestamp': timestamp,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Scrobble.fromMap(Map<String, dynamic> map) {
    return Scrobble(
      id: map['id'] as int?,
      artist: map['artist'] as String,
      track: map['track'] as String,
      album: map['album'] as String?,
      timestamp: map['timestamp'] as int,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }
}