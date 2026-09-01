import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_player_app/data/providers/sync_provider.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/presentation/screens/settings_screen.dart';
import 'package:music_player_app/data/services/database_service.dart';
import 'package:music_player_app/data/services/filesystem_service.dart';
import 'package:music_player_app/data/repositories/music_folder_repository.dart';
import 'package:music_player_app/data/repositories/song_repository.dart';
import 'package:music_player_app/domain/managers/sync_manager.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockFilesystemService extends Mock implements FilesystemService {}
class MockMusicFolderRepository extends Mock implements MusicFolderRepository {}
class MockSongRepository extends Mock implements SongRepository {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeRoute extends Fake implements Route<dynamic> {}

class MockSyncManager extends Mock implements SyncManager {
  @override
  Future<void> forceSync();
}

void main() {
  late MockDatabaseService mockDb;
  late MockFilesystemService mockFs;
  late MockMusicFolderRepository mockMusicFolderRepo;
  late MockSongRepository mockSongRepo;
  late MockSyncManager mockSyncManager;

  setUpAll(() {
    registerFallbackValue(FakeRoute());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockFs = MockFilesystemService();
    mockMusicFolderRepo = MockMusicFolderRepository();
    mockSongRepo = MockSongRepository();
    mockSyncManager = MockSyncManager();

    // Stub the initial tilt database load
    when(() => mockDb.getValue('tilt_enabled')).thenAnswer((_) async => const Success('true'));
  });

  Widget buildTestable({NavigatorObserver? observer}) {
    return ProviderScope(
      overrides: [
        syncManagerProvider.overrideWithValue(mockSyncManager),
      ],
      child: MaterialApp(
        navigatorObservers: observer != null ? [observer] : [],
        home: Scaffold(
          body: SettingsScreen(
            testDatabaseService: mockDb,
            testFilesystemService: mockFs,
            testMusicFolderRepository: mockMusicFolderRepo,
            testSongRepository: mockSongRepo,
          ),
        ),
      ),
    );
  }

  group('SettingsScreen Widget Tests', () {
    
    testWidgets('Initializes and loads tilt setting from DB', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchWidget.value, true); 
    });

    testWidgets('Toggling Tilt Switch updates the Database', (tester) async {
      when(() => mockDb.insertKVPair('tilt_enabled', 'false')).thenAnswer((_) async => Success(unit));
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tilt to Move Player'));
      await tester.pumpAndSettle();

      verify(() => mockDb.insertKVPair('tilt_enabled', 'false')).called(1);
    });

    testWidgets('Scanning for music displays success message', (tester) async {
      when(() => mockMusicFolderRepo.scanFolder()).thenAnswer((_) async => Success(unit));

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Look for new music'));
      await tester.pump(); 
      await tester.pump(); 

      expect(find.text('Music scan completed!'), findsOneWidget);
    });

    testWidgets('Navigation to Equalizer pushes new route', (tester) async {
      final mockObserver = MockNavigatorObserver();
      
      await tester.pumpWidget(buildTestable(observer: mockObserver));
      await tester.pumpAndSettle();
      clearInteractions(mockObserver);

      final equalizerItem = find.text('Equalizer');
      await tester.ensureVisible(equalizerItem);
      await tester.pumpAndSettle();

      await tester.tap(equalizerItem);
      await tester.pump();
      
      verify(() => mockObserver.didPush(any(), any())).called(1);
    });

    testWidgets('Navigation to Last.fm pushes new route', (tester) async {
      final mockObserver = MockNavigatorObserver();
      
      await tester.pumpWidget(buildTestable(observer: mockObserver));
      await tester.pumpAndSettle();
      clearInteractions(mockObserver);

      final lastFmItem = find.text('Last.fm Login');
      await tester.ensureVisible(lastFmItem);
      await tester.pumpAndSettle();

      await tester.tap(lastFmItem);
      await tester.pump();
      
      verify(() => mockObserver.didPush(any(), any())).called(1);
    });

    testWidgets('Force Sync triggers SyncManager', (tester) async {
      when(() => mockSyncManager.forceSync()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Ensure the button is scrolled into view before tapping
      final syncItem = find.text('Force Sync Last.fm');
      await tester.ensureVisible(syncItem);
      await tester.pumpAndSettle();

      await tester.tap(syncItem);
      await tester.pump(); 

      verify(() => mockSyncManager.forceSync()).called(1);
      
      await tester.pumpAndSettle(); 
      expect(find.text('Offline sync cycle completed.'), findsOneWidget);
    });
  });
}