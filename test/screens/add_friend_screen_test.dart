import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/models/friend.dart';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/models/use_item_result.dart';
import 'package:trak/models/user_profile.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/repository/app_repository.dart';
import 'package:trak/screens/add_friend_screen.dart';

class _FakeRepository implements AppRepository {
  bool shouldThrow = false;
  String? lastAddedFriend;

  @override
  Future<void> addFriend(String username) async {
    if (shouldThrow) throw Exception('User not found');
    lastAddedFriend = username;
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() => Stream.value([]);
  @override
  Stream<List<InventoryItem>> watchInventory() => Stream.value([]);
  @override
  Stream<int> watchStepCount() => Stream.value(0);
  @override
  Future<UserProfile> getCurrentUser() async => const UserProfile(
    userId: 'u1',
    username: 'testuser',
    displayName: 'Test User',
  );
  @override
  Future<void> putSteps(int stepCount) async {}
  @override
  Future<UseItemResult> useItem(String itemId, String targetUserId) async =>
      const UseItemResult.success();
  @override
  Future<void> removeFriend(String friendId) async {}

  @override
  Stream<List<Friend>> watchFriends() => Stream.value([
    Friend(
      userId: 'user-000',
      friendId: 'alice123',
      createdAt: '2026-05-18T12:00:00Z',
    ),
    Friend(
      userId: 'user-002',
      friendId: 'alex_walks',
      createdAt: '2026-05-18T12:00:00Z',
    ),
    Friend(
      userId: 'user-003',
      friendId: 'steph_steps',
      createdAt: '2026-05-18T12:00:00Z',
    ),
  ]);
}

Widget _wrap(_FakeRepository repo) => ProviderScope(
  overrides: [repositoryProvider.overrideWithValue(repo)],
  child: const MaterialApp(home: AddFriendScreen()),
);

void main() {
  group('AddFriendScreen', () {
    late _FakeRepository repo;

    setUp(() => repo = _FakeRepository());

    testWidgets('renders text field and button', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Add Friend'), findsWidgets);
    });

    testWidgets('shows Add Friend in app bar', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      expect(find.widgetWithText(AppBar, 'Add Friend'), findsOneWidget);
    });

    testWidgets('empty submit does not call repository', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Friend'));
      await tester.pump();
      expect(repo.lastAddedFriend, isNull);
    });

    testWidgets('successful add shows success message', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.tap(find.widgetWithText(FilledButton, 'Add Friend'));
      await tester.pump();
      expect(find.text('alice added!'), findsOneWidget);
      expect(repo.lastAddedFriend, 'alice');
    });

    testWidgets('successful add clears text field', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.tap(find.widgetWithText(FilledButton, 'Add Friend'));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'alice'), findsNothing);
    });

    testWidgets('failed add shows error message', (tester) async {
      repo.shouldThrow = true;
      await tester.pumpWidget(_wrap(repo));
      await tester.enterText(find.byType(TextField), 'ghost');
      await tester.tap(find.widgetWithText(FilledButton, 'Add Friend'));
      await tester.pump();
      expect(find.textContaining('User not found'), findsOneWidget);
    });

    testWidgets('submit via keyboard triggers add', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      await tester.enterText(find.byType(TextField), 'bob');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.lastAddedFriend, 'bob');
    });
  });
}
