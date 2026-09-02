import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

// Adjust these imports to match your project's folder structure
import 'package:music_player_app/domain/managers/scrobble_manager.dart';
import 'package:music_player_app/data/services/last_fm_service.dart';
import 'package:music_player_app/data/repositories/scrobble_repository.dart';
import 'package:music_player_app/domain/models/scrobble/scrobble.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}
class MockLastFmService extends Mock implements LastFmService {}
class MockScrobbleRepository extends Mock implements ScrobbleRepository {}

// Use mocks to bypass the complex constructors of just_audio classes
class MockSequenceState extends Mock implements SequenceState {}
class MockIndexedAudioSource extends Mock implements IndexedAudioSource {}
class FakeScrobble extends Fake implements Scrobble {}

void main() {
  late MockAudioPlayer mockAudioPlayer;
  late MockLastFmService mockLastFmService;
  late MockScrobbleRepository mockScrobbleRepository;
  late ScrobbleManager scrobbleManager;

  late StreamController<SequenceState?> sequenceStateController;
  late StreamController<Duration> positionController;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 0));
    // Required so mocktail can use any() with Scrobble parameters
    registerFallbackValue(FakeScrobble()); 
  });

  setUp(() {
    mockAudioPlayer = MockAudioPlayer();
    mockLastFmService = MockLastFmService();
    mockScrobbleRepository = MockScrobbleRepository();

    sequenceStateController = StreamController<SequenceState?>.broadcast();
    positionController = StreamController<Duration>.broadcast();

    when(() => mockAudioPlayer.sequenceStateStream)
        .thenAnswer((_) => sequenceStateController.stream);
    when(() => mockAudioPlayer.positionStream)
        .thenAnswer((_) => positionController.stream);
    when(() => mockAudioPlayer.duration).thenReturn(const Duration(seconds: 200));

    scrobbleManager = ScrobbleManager(
      audioPlayer: mockAudioPlayer,
      lastFmService: mockLastFmService,
      scrobbleRepository: mockScrobbleRepository,
    );
  });

  tearDown(() {
    sequenceStateController.close();
    positionController.close();
  });

  group('ScrobbleManager Tests', () {
    test('sends Now Playing when track changes and session key is active', () async {
      when(() => mockLastFmService.updateNowPlaying(any(), any()))
          .thenAnswer((_) async => {});

      scrobbleManager.updateSessionKey('fake_session_key');
      scrobbleManager.startListening();

      final fakeMediaItem = MediaItem(
        id: 'track_1',
        title: 'Song Title',
        artist: 'Artist Name',
        album: 'Album Name',
      );

      // Construct the mock audio source
      final mockSource = MockIndexedAudioSource();
      when(() => mockSource.tag).thenReturn(fakeMediaItem);

      // Construct the mock sequence state
      final mockSequenceState = MockSequenceState();
      when(() => mockSequenceState.currentSource).thenReturn(mockSource);
      when(() => mockSequenceState.sequence).thenReturn([mockSource]);

      // Ensure the synchronous getter matches the stream event
      when(() => mockAudioPlayer.sequenceState).thenReturn(mockSequenceState);
      sequenceStateController.add(mockSequenceState);

      // Allow microtasks to execute so the stream listener can process the event
      await pumpEventQueue();

      verify(() => mockLastFmService.updateNowPlaying(any(), 'fake_session_key')).called(1);

      scrobbleManager.stopListening();
    });

    test('reaches scrobble threshold when position exceeds 50% of duration', () async {
      when(() => mockScrobbleRepository.insertScrobble(any()))
          .thenAnswer((_) async => 1);
      when(() => mockLastFmService.scrobble(any(), any()))
          .thenAnswer((_) async => {});
      when(() => mockScrobbleRepository.markAsSynced(any()))
          .thenAnswer((_) async => {});

      scrobbleManager.updateSessionKey('fake_session_key');
      scrobbleManager.startListening();

      final fakeMediaItem1 = MediaItem(
        id: 'track_1',
        title: 'Song 1',
        artist: 'Artist 1',
      );

      final mockSource1 = MockIndexedAudioSource();
      when(() => mockSource1.tag).thenReturn(fakeMediaItem1);

      final mockSequenceState1 = MockSequenceState();
      when(() => mockSequenceState1.currentSource).thenReturn(mockSource1);
      when(() => mockSequenceState1.sequence).thenReturn([mockSource1]);

      // Start track 1 and update the synchronous getter
      when(() => mockAudioPlayer.sequenceState).thenReturn(mockSequenceState1);
      sequenceStateController.add(mockSequenceState1);
      await pumpEventQueue();

      // Simulate playback reaching 101 seconds (duration is 200s, threshold is 100s)
      positionController.add(const Duration(seconds: 101));
      await pumpEventQueue();

      final fakeMediaItem2 = MediaItem(
        id: 'track_2',
        title: 'Song 2',
        artist: 'Artist 2',
      );

      final mockSource2 = MockIndexedAudioSource();
      when(() => mockSource2.tag).thenReturn(fakeMediaItem2);

      final mockSequenceState2 = MockSequenceState();
      when(() => mockSequenceState2.currentSource).thenReturn(mockSource2);
      when(() => mockSequenceState2.sequence).thenReturn([mockSource1, mockSource2]);

      // Switch to track 2 and update the synchronous getter to trigger _processPendingScrobble
      when(() => mockAudioPlayer.sequenceState).thenReturn(mockSequenceState2);
      sequenceStateController.add(mockSequenceState2);
      await pumpEventQueue();

      // Verify scrobble was saved and synced
      verify(() => mockScrobbleRepository.insertScrobble(any())).called(1);
      verify(() => mockLastFmService.scrobble(any(), 'fake_session_key')).called(1);
      verify(() => mockScrobbleRepository.markAsSynced([1])).called(1);

      scrobbleManager.stopListening();
    });
  });
}