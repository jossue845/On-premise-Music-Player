import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_app/presentation/components/app_theme.dart';
// Adjust this import to match your project's structure
void main() {
  group('AppTheme Tests', () {
    test('darkTheme generates valid ThemeData with correct core colors', () {
      final theme = AppTheme.darkTheme;

      // 1. Verify Scaffold and Primary Colors
      expect(theme.scaffoldBackgroundColor, Colors.black);
      expect(theme.primaryColor, Colors.cyanAccent);
      
      // 2. Verify Surface Colors
      expect(theme.colorScheme.surface, const Color(0xFF16213E));
      expect(theme.cardTheme.color, const Color(0xFF16213E));
      
      // 3. Verify Text Typography 
      expect(theme.textTheme.bodyLarge?.color, Colors.white);
      expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Roboto');
    });
  });
}