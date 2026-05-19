import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/repository/cloud_repository.dart';
import 'package:trak/screens/username_screen.dart';

class _FakeCloud extends CloudRepository {
  bool shouldThrowTaken = false;
  bool shouldThrow = false;
  String? lastUsername;

  @override
  Future<void> setUsername(String username) async {
    if (shouldThrowTaken) throw const UsernameAlreadyTakenException();
    if (shouldThrow) throw Exception('network error');
    lastUsername = username;
  }
}

Widget _wrap(_FakeCloud cloud) => ProviderScope(
  overrides: [
    cloudRepositoryProvider.overrideWithValue(cloud),
    needsUsernameProvider.overrideWith((ref) async => true),
  ],
  child: const MaterialApp(home: UsernameScreen()),
);

void main() {
  group('UsernameScreen', () {
    late _FakeCloud cloud;

    setUp(() => cloud = _FakeCloud());

    testWidgets('renders text field, button, and app bar', (tester) async {
      await tester.pumpWidget(_wrap(cloud));
      expect(find.widgetWithText(AppBar, 'Choose a username'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    });

    testWidgets('empty submit shows required error without calling repo',
        (tester) async {
      await tester.pumpWidget(_wrap(cloud));
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      expect(find.text('Username is required'), findsOneWidget);
      expect(cloud.lastUsername, isNull);
    });

    testWidgets('username under 3 characters shows format error', (tester) async {
      await tester.pumpWidget(_wrap(cloud));
      await tester.enterText(find.byType(TextFormField), 'ab');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      expect(
        find.text('3–20 characters: letters, numbers, and underscores only'),
        findsOneWidget,
      );
      expect(cloud.lastUsername, isNull);
    });

    testWidgets('username with invalid characters shows format error',
        (tester) async {
      await tester.pumpWidget(_wrap(cloud));
      await tester.enterText(find.byType(TextFormField), 'bad name!');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      expect(
        find.text('3–20 characters: letters, numbers, and underscores only'),
        findsOneWidget,
      );
      expect(cloud.lastUsername, isNull);
    });

    testWidgets('valid username calls setUsername on repo', (tester) async {
      await tester.pumpWidget(_wrap(cloud));
      await tester.enterText(find.byType(TextFormField), 'valid_user');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      expect(cloud.lastUsername, 'valid_user');
    });

    testWidgets('already taken shows server error', (tester) async {
      cloud.shouldThrowTaken = true;
      await tester.pumpWidget(_wrap(cloud));
      await tester.enterText(find.byType(TextFormField), 'taken_user');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      expect(find.text('Username already taken'), findsOneWidget);
    });

    testWidgets('network error shows generic error', (tester) async {
      cloud.shouldThrow = true;
      await tester.pumpWidget(_wrap(cloud));
      await tester.enterText(find.byType(TextFormField), 'valid_user');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('keyboard submit triggers setUsername', (tester) async {
      await tester.pumpWidget(_wrap(cloud));
      await tester.enterText(find.byType(TextFormField), 'keyboard_user');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(cloud.lastUsername, 'keyboard_user');
    });
  });
}
