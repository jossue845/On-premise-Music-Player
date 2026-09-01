import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import 'package:music_player_app/presentation/screens/listening_habits_screen.dart';
import 'package:music_player_app/data/services/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();

    // Prevent the real DB from attempting to open
    when(() => mockDb.isOpen()).thenReturn(true);

    when(() => mockDb.getListeningHabits()).thenAnswer(
      (_) async => const Success({'topDay': 'Friday', 'peakTime': 'Late Night'}),
    );
    
    when(() => mockDb.getHeatmapData()).thenAnswer(
      (_) async => const Success(<Map<String, dynamic>>[]), 
    );

    // --- FIX: Add the missing stub for the total time listened ---
    when(() => mockDb.getValue('total_time_listened')).thenAnswer(
      (_) async => const Success('7200'), // 2 hours
    );
  });

  Widget createHabitsScreen() {
    return MaterialApp(
      home: ListeningHabitsScreen(
        testDatabaseService: mockDb,
      ),
    );
  }

  group('Listening Habits Screen Widget Tests', () {
    
    testWidgets('Renders top day and peak time correctly from database', (WidgetTester tester) async {
      await tester.pumpWidget(createHabitsScreen());
      
      // We can safely use pumpAndSettle now because the async function will successfully finish!
      await tester.pumpAndSettle();

      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Late Night'), findsOneWidget);
      
      // Let's also verify it formats the 7200 seconds correctly
      expect(find.text('2h 0m'), findsOneWidget);
    });

  });
}