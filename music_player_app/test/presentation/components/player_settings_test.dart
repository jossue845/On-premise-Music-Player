import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart'; 
import 'package:music_player_app/presentation/components/player_settings.dart';

void main() {
  group('PlayerSettings Widget Tests', () {
    testWidgets('renders child and applies neumorphic decoration', (WidgetTester tester) async {
      const testKey = Key('child_text_key');

      // 1. Pump the widget into the test environment
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerSettings(
              child: Text('Settings Content', key: testKey),
            ),
          ),
        ),
      );

      // 2. Verify the child is successfully passed and rendered
      expect(find.byKey(testKey), findsOneWidget);
      expect(find.text('Settings Content'), findsOneWidget);

      // 3. Extract the Container to verify the decoration properties
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byKey(testKey), 
          matching: find.byType(Container),
        ).first,
      );
      
      final decoration = container.decoration as BoxDecoration;
      
      // Verify Base Color and Radius
      expect(decoration.color, const Color(0xFF121212));
      expect(decoration.borderRadius, BorderRadius.circular(16));
      
      // Verify the Dual-Shadow System
      expect(decoration.boxShadow?.length, 2);
      expect(decoration.boxShadow?[0].color, Colors.black);
      expect(decoration.boxShadow?[1].color, const Color(0xFF262626));
    });
  });
}