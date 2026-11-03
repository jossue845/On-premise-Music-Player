# OffPulse

<p align="center">
  <strong>A smarter local music player. Offline by design, richer when connected.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Architecture-4--Tier-blueviolet" alt="Architecture" />
  <img src="https://img.shields.io/badge/Database-SQLite-003B57?logo=sqlite" alt="SQLite" />
  <img src="https://img.shields.io/badge/State-Riverpod-black" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Audio-JustAudio-orange" alt="JustAudio" />
</p>

---

## Overview

**OffPulse** is an advanced, offline-first mobile audio player engineered using Flutter. While the modern streaming ecosystem provides convenience, it compromises on data sovereignty, catalog permanence, offline reliability, and privacy. OffPulse addresses this problem by treating local, user-owned audio collections as first-class citizens.

The application combines a self-contained on-device relational database engine (SQLite) with an asynchronous metadata enrichment pipeline. When offline, OffPulse operates with zero latency, managing persistent playback queues, audio decoding, and local analytics. When connectivity is available, it gracefully queries external REST services to heal incomplete legacy ID3 tags, fetch synchronized lyrics, download high-resolution cover art, and batch-synchronize scrobbles to Last.fm.

---

## Key Features

### 1. Library Ingestion & File-Level Tag Editing
- **Asynchronous Storage Traversal**: Discovers local audio formats recursively across custom filesystem directories.
- **Physical Tag Rewrite**: Modifies ID3 container frames (`TIT2`, `TPE1`, `TALB`, `TCON`, `TYER`) directly on the storage media via native bindings, ensuring tag edits persist outside the application.
- **Auto-Fix Assistance**: Automatically queries online catalogs to resolve incomplete or poorly ripped track tags with interactive user confirmation.

### 2. Multi-Tier Fallback Metadata Enrichment
- **Automated Artwork Resolution**: Queries **TheAudioDB** for high-resolution release-group artwork and seamlessly cascades to the **iTunes Search API** if primary queries return empty.
- **Synchronized Lyrics**: Connects to **LRCLIB** utilizing exact title-artist-album endpoints, falling back to approximate fuzzy matching on 404 responses to render line-by-line synchronized LRC lyrics.

### 3. Native Audio Processing & Equalization
- **Audio Pipeline**: Leverages `just_audio` with low-latency seeking, looping, and gapless `ConcatenatingAudioSource` queue management.
- **Android Native Equalizer**: Interfaces with `AndroidEqualizerParameters` to provide real-time multi-band frequency gain and preamp control.
- **Persistent EQ Presets**: Serializes customized audio curves to local storage for instant recall.

### 4. Hardware-Assisted UI & Wear OS Integration
- **Tilt-to-Move Floating Mini-Player**: Consumes raw hardware streams from `sensors_plus` (`accelerometerEventStream`). Raw values pass through coordinate thresholds and a 150 ms software throttle to relocate floating player controls via `AnimatedPositioned` widgets.
- **Wear OS Companion**: Provides a synchronized wearable interface for remote playback commands (play/pause/skip) and real-time metadata display.

### 5. Private Telemetry & Batched Scrobbling
- **On-Device Analytics**: Generates hourly heatmaps and top-day matrices directly in SQLite without cloud dependencies.
- **Offline Scrobble Buffer**: Queues playback milestones crossing the 50% threshold in an internal buffer.
- **Batched Sync**: Automatically batches pending scrobbles into chunks of up to 50 items to upload to **Last.fm** once connectivity is restored, avoiding API rate-limiting and reducing battery consumption.

---

## System Architecture

OffPulse is built around a strict **4-Tier Architecture**, enforcing clean separation between UI rendering, business rules, external integrations, and local data persistence.

```
┌─────────────────────────────────────────────────────────────┐
│                 Presentation Layer (Flutter)                │
│       Material 3 UI, Screen Widgets, Hardware Controls      │
└──────────────────────────────┬──────────────────────────────┘
                               │ Dispatches Events / Subscribes
                               ▼
┌─────────────────────────────────────────────────────────────┐
│            Business Logic Layer (Riverpod & Managers)       │
│     audioPlayerProvider, SyncManager, ScrobbleManager       │
└──────────────────────────────┬──────────────────────────────┘
                               │ Calls Domain Repositories
                               ▼
┌─────────────────────────────────────────────────────────────┐
│           Integration Layer (Repositories & Services)       │
│  SongRepository, PlaylistRepository, QueueRepository, APIs  │
└──────────────────────────────┬──────────────────────────────┘
                               │ I/O Operations & REST
                               ▼
┌─────────────────────────────────────────────────────────────┐
│             Data Layer (SQLite & Native Storage)            │
│   SQLite Database (8 Tables), Secure Storage, Local Disk    │
└─────────────────────────────────────────────────────────────┘
```

### Architectural Decisions & Rationale

| Decision | Implementation | Architectural Justification |
| :--- | :--- | :--- |
| **Architectural Pattern** | 4-Tier Architecture | Fully decouples the UI from data queries and network endpoints, keeping UI widgets lightweight and business logic independently testable. |
| **State Management & DI** | Riverpod | Compile-time safe dependency injection outside the widget tree. Allows managers and background audio services to read/write state without a `BuildContext`. |
| **Data Abstraction** | Repository Pattern | Concrete repositories (`SongRepository`, `PlaylistRepository`, etc.) abstract raw SQL and file I/O operations away from the business layer. |
| **Local Persistence** | SQLite (`sqflite`) | Normalized relational schema. Music collections are inherently relational (Songs $\leftrightarrow$ Albums $\leftrightarrow$ Artists $\leftrightarrow$ Playlists); relational models avoid the consistency issues of NoSQL. |
| **Data Integrity** | SQL Database Triggers | Cascading database triggers prune orphaned `album` and `artist` records upon track modifications directly inside atomic transactions. |
| **Secure Storage** | `flutter_secure_storage` | Sensitive Last.fm session tokens are kept isolated from the media database and stored in platform-encrypted storage (Android Keystore). |
| **Reactive Streams** | Observer Pattern | Dart streams (`positionStream`, `accelerometerEventStream`) deliver live audio and sensor events without inefficient polling loops. |
| **Fault Tolerance** | Fallback Pattern | Cascading API lookups (TheAudioDB $\rightarrow$ iTunes; LRCLIB Exact $\rightarrow$ Fuzzy) maximize metadata resolution across inconsistent catalogs. |
| **Network Optimization** | Batch Processing | Buffers offline scrobbles and dispatches them in 50-track batches, minimizing HTTP overhead and conserving battery life. |

---

## Database Schema Design

The SQLite database contains 8 tables organized into core media entities, playback queue state, and telemetry buffers:

```
┌──────────────┐       ┌──────────────┐
│    artist    │       │    album     │
├──────────────┤       ├──────────────┤
│ id (PK)      │◄──┐   │ id (PK)      │◄──┐
│ name         │   └───┼─ artist_id   │   │
└──────────────┘       │ title        │   │
                       └──────────────┘   │
                                          │
┌──────────────┐       ┌──────────────┐   │
│   playlist   │       │     song     │   │
├──────────────┤       ├──────────────┤   │
│ id (PK)      │◄──┐   │ id (PK)      │   │
│ name         │   │   │ file_path    │   │
└──────────────┘   │   │ title        │   │
                   │   │ album_id (FK)├───┘
┌──────────────────┴─┐ │ artist_id(FK)├───┘
│   playlist_track   │ │ lyrics       │
├────────────────────┤ │ play_count   │
│ playlist_id (FK)   │ │ favorite     │
│ song_id (FK)       │ └──────────────┘
│ track_order        │
└────────────────────┘
```

* **`song`**: Physical file paths, parsed ID3 metadata, foreign keys, play counts, favorite flags, and cached lyrics.
* **`artist`** & **`album`**: Normalized catalog entities automatically maintained via cascading database triggers.
* **`playlist`** & **`playlist_track`**: Relational junction table modeling custom playlist compositions with explicit ordering.
* **`queued_song`**: Persists the active playback sequence, custom shuffle indices, and active pointer across reboots.
* **`scrobble`**: Buffers offline playback events (timestamps, track IDs, sync flags) for Last.fm sync.
* **`kv_store`**: Key-value table storing serialized EQ presets, music folder paths, and telemetry statistics.

---

## External Integrations

| Service | Target Endpoints | Role | Resilience Strategy |
| :--- | :--- | :--- | :--- |
| **TheAudioDB** | `/searchalbum.php`<br>`/searchtrack.php` | Primary album art & track metadata | Falls back to iTunes on 404 or empty results |
| **iTunes API** | `/search?term=...` | Secondary artwork resolution | Dynamic dimension resizing (`500x500bb`) |
| **LRCLIB** | `/api/get`<br>`/api/search` | Synchronized and plain LRC lyrics | Exact lookup falls back to fuzzy title/artist search |
| **Last.fm** | `track.scrobble`<br>`track.updateNowPlaying` | Playback telemetry & history | Local SQLite buffering with 50-item batched sync |

---

## Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0 or higher recommended)
* Dart SDK (v3.3.0 or higher)
* Android SDK (API Level 26+ for native equalizer and audio focus handling)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/OffPulse.git
   cd OffPulse
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation (if using model serialization):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

---

## Testing Strategy

OffPulse employs a three-tier testing strategy:

* **Unit Tests**: Headless testing of business logic, state transformations, and repositories using standalone Riverpod `ProviderContainer` instances without UI overhead.
* **Integration Tests**: Verification of SQLite transactions, database trigger cascading, batch playlist delta calculations, and simulated fallback network chains.
* **Hardware & Widget Tests**: Sensor stream throttling validation, `AnimatedPositioned` coordinate bounds checking, and Wear OS message synchronization latency tests.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for full details.
