import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/auth/auth_notifier.dart';
import 'package:trak/auth/login_screen.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier({
    this.initialUser,
    this.shouldThrow = false,
    this.stayLoading = false,
  });

  final AuthUser? initialUser;
  final bool shouldThrow;
  final bool stayLoading;
  bool signInCalled = false;

  @override
  Future<AuthUser?> build() async {
    if (shouldThrow) throw Exception('Auth failed');
    if (stayLoading) await Completer<void>().future;
    return initialUser;
  }

  @override
  Future<void> signInWithGoogle() async {
    signInCalled = true;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> refresh() async {}
}

Widget _buildTestWidget(_FakeAuthNotifier notifier) {
  return ProviderScope(
    overrides: [authStateProvider.overrideWith(() => notifier)],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('shows title and tagline', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_FakeAuthNotifier()));
      await tester.pump();

      expect(find.text('Trak'), findsOneWidget);
      expect(find.text('Track steps. Challenge friends.'), findsOneWidget);
    });

    testWidgets('shows Google sign-in button when idle', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_FakeAuthNotifier()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows loading indicator while auth is in progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(_FakeAuthNotifier(stayLoading: true)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows error message when sign-in fails', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(_FakeAuthNotifier(shouldThrow: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in failed. Please try again.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('does not show error message when idle', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_FakeAuthNotifier()));
      await tester.pump();

      expect(find.text('Sign in failed. Please try again.'), findsNothing);
    });

    testWidgets('tapping Google button calls signInWithGoogle', (tester) async {
      final notifier = _FakeAuthNotifier();
      await tester.pumpWidget(_buildTestWidget(notifier));
      await tester.pump();

      await tester.tap(find.byType(Image));
      await tester.pump();

      expect(notifier.signInCalled, isTrue);
    });
  });
}
