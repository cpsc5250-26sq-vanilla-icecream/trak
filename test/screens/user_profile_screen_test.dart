import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/auth/auth_notifier.dart';

import 'package:trak/models/friend.dart';
import 'package:trak/models/user_profile.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/screens/user_profile_screen.dart';

Widget _wrap({
  UserProfile? profile,
  List<Friend> friends = const [],
  int points = 0,
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith(
        (ref) async =>
            profile ??
            const UserProfile(
              userId: 'user-1',
              username: 'tester',
              displayName: 'Kyle',
            ),
      ),
      friendsProvider.overrideWith((ref) => Stream.value(friends)),
      currentUserPointsProvider.overrideWith((ref) => points),
    ],
    child: const MaterialApp(home: UserProfileScreen()),
  );
}

final friend1 = Friend(
  userId: 'user-1',
  friendId: 'friend-1',
  username: 'alice',
  displayName: 'Alice',
  createdAt: '2026-01-01',
);

final friend2 = Friend(
  userId: 'user-1',
  friendId: 'friend-2',
  username: 'bob',
  displayName: 'Bob',
  createdAt: '2026-01-01',
);

class TestAuthNotifier extends AuthNotifier {
  bool signOutCalled = false;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

void main() {
  group('UserProfileScreen', () {
    testWidgets('shows username when profile is opened', (tester) async {
      await tester.pumpWidget(_wrap(friends: [friend1, friend2]));

      await tester.pumpAndSettle();

      expect(find.text('@tester'), findsOneWidget);
    });

    testWidgets('shows display name when profile is opened', (tester) async {
      await tester.pumpWidget(_wrap(friends: [friend1, friend2]));

      await tester.pumpAndSettle();

      expect(find.text('Kyle'), findsOneWidget);
    });

    testWidgets('shows the proper friend count on the profile page', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(friends: [friend1, friend2]));

      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
    });

    testWidgets(
      'shows the proper total points the app currently calculated on the profile apge',
      (tester) async {
        await tester.pumpWidget(_wrap(points: 250));

        await tester.pumpAndSettle();

        expect(find.text('250'), findsOneWidget);
        expect(find.text('Total Points'), findsOneWidget);
      },
    );

    testWidgets('shows edit profile button', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows avatar icon when avatar url is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          profile: const UserProfile(
            userId: 'user-1',
            username: 'tester',
            displayName: 'Kyle',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets(
      'the display name is the username when the display name is empty',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            profile: const UserProfile(
              userId: 'user-1',
              username: 'tester',
              displayName: '',
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('tester'), findsOneWidget);
        expect(find.text('@tester'), findsOneWidget);
      },
    );

    testWidgets('shows logout button on the profile page', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets(
      'logout button calls signOut callback function that properly logs out the user',
      (tester) async {
        final notifier = TestAuthNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(() => notifier),
              currentUserProvider.overrideWith(
                (ref) async => const UserProfile(
                  userId: 'user-1',
                  username: 'tester',
                  displayName: 'Kyle',
                ),
              ),
              friendsProvider.overrideWith((ref) => Stream.value([])),
              currentUserPointsProvider.overrideWith((ref) => 0),
            ],
            child: const MaterialApp(home: UserProfileScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.logout));
        await tester.pump();

        expect(notifier.signOutCalled, isTrue);
      },
    );
    testWidgets('shows error message when profile fails to load', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) async => throw Exception('Failed to load profile'),
            ),
          ],
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
    });
  });
}
