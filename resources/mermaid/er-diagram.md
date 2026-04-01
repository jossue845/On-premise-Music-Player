```mermaid
erDiagram
    direction LR
    SONG{
        int song_id PK
        string song_title
        int album_id FK
        string genre
        int year
        int bitrate
        int track_number
        string path
        string image_id
    }
    PLAYLIST{
        int playlist_id PK
        string playlist_title
    }
    PLAYLIST_TRACK{
        int playlist_id PK, FK
        int song_id PK, FK
    }

    QUEUED_SONG{
        string song_id PK, FK
        int position
        bool current_song
    }
    SONG_ARTIST{
        int song_id PK, FK
        int artist_id PK, FK
    }
    ALBUM{
        int album_id PK
        string album_title
    }
    ARTIST{
        int artist_id PK
        string name
    }
    ALBUM_ARTIST{
        int song_id PK, FK
        int artist_id PK, FK
    }
    PLAYLIST_TRACK }o--|| SONG : "is"
    PLAYLIST ||--o{ PLAYLIST_TRACK : "contains"
    QUEUED_SONG o|--|| SONG : "is"
    SONG |{--|| ALBUM : "in"
    SONG ||--|{ SONG_ARTIST : "made by"
    ALBUM ||--|{ ALBUM_ARTIST : "made by"
    SONG_ARTIST o{--|| ARTIST: "is"
    ALBUM_ARTIST o{--|| ARTIST: "is"
```
```
