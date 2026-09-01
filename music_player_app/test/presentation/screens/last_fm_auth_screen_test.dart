import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
// Adjust these imports to match your project structure
import 'package:music_player_app/presentation/screens/lastfm_screen.dart';
import 'package:music_player_app/data/providers/auth_provider.dart';

// 1. Create a Fake Notifier to control the authentication state during tests.
// Note: Adjust the extended class (e.g., AsyncNotifier, StateNotifier) based 
// on exactly how your AuthNotifier is defined in auth_provider.dart.
class FakeAuthNotifier extends AsyncNotifier<String?> implements AuthNotifier {
  @override
  Future<String?> build() async => null;

  @override
  Future<void> login(String username, String password) async {
    // Force a loading state
    state = const AsyncLoading();
    
    // Simulate network delay for the test to catch the loading spinner
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (username == 'wrong_user') {
      state = AsyncError(Exception('Invalid credentials'), StackTrace.empty);
    } else {
      state = const AsyncData('fake_session_key_123');
    }
  }

  @override
  Future<void> logout() async {
    state = const AsyncData(null);
  }
}

void main() {
  Widget buildTestable() {
    return ProviderScope(
      overrides: [
        // 2. Override the real provider with our Fake Notifier
        authProvider.overrideWith(() => FakeAuthNotifier()),
      ],
      child: const MaterialApp(
        home: LastFmAuthScreen(),
      ),
    );
  }

  group('LastFmAuthScreen Widget Tests', () {
    testWidgets('Renders login form initially', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      expect(find.text('Last.fm'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Connect Account'), findsOneWidget);
    });

    testWidgets('Shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Tap submit without entering text
      await tester.tap(find.text('Connect Account'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Shows loading indicator and then success view on valid login', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).first, 'valid_user');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap submit
      await tester.tap(find.text('Connect Account'));
      
      // Pump one frame to trigger the AsyncLoading state
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Settle the remaining frames to allow the Future to resolve to AsyncData
      await tester.pumpAndSettle();

      // Verify the UI changed to the success view
      expect(find.text('Connected to Last.fm'), findsOneWidget);
      expect(find.text('Disconnect Account'), findsOneWidget);
    });

    testWidgets('Shows error SnackBar on failed login', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pumpAndSettle();

      // Enter credentials designed to fail in our FakeAuthNotifier
      await tester.enterText(find.byType(TextFormField).first, 'wrong_user');
      await tester.enterText(find.byType(TextFormField).last, 'wrong_pass');

      await tester.tap(find.text('Connect Account'));
      
      // Fast forward past the loading state
      await tester.pumpAndSettle();

      // Verify the Snackbar appears with the error message
      expect(find.text('Invalid credentials'), findsOneWidget);
      
      // Verify we are still on the login form
      expect(find.text('Connect Account'), findsOneWidget);
    });
  });
}