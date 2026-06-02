import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/models/friend.dart';
import 'package:trak/models/friend_request.dart';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/models/use_item_result.dart';
import 'package:trak/models/user_profile.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/repository/app_repository.dart';
import 'package:trak/screens/powerup_screen.dart';

class _FakeRepository implements AppRepository {
  String? usedItemId;
  String? usedTargetId;

  final List<InventoryItem> inventory;
  final List<Friend> friends;

  _FakeRepository({this.inventory = const [], this.friends = const []});

  @override
  Stream<List<InventoryItem>> watchInventory() => Stream.value(inventory);

  @override
  Stream<List<Friend>> watchFriends() => Stream.value(friends);

  @override
  Future<UseItemResult> useItem(String itemId, String targetUserId) async {
    usedItemId = itemId;
    usedTargetId = targetUserId;
    return const UseItemResult.success();
  }

  @override
  Future<UserProfile> getCurrentUser() async => const UserProfile(
    userId: 'me',
    username: 'tester',
    displayName: 'Tester',
  );

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() => Stream.value([]);

  @override
  Stream<int> watchStepCount() => Stream.value(0);

  @override
  Future<void> putSteps(int stepCount) async {}

  @override
  Future<void> addFriend(String username) async {}

  @override
  Future<void> removeFriend(String friendId) async {}

  @override
  Future<List<FriendRequest>> getFriendRequests() async => [];

  @override
  Future<void> acceptFriendRequest(String fromUserId) async {}

  @override
  Future<void> declineFriendRequest(String fromUserId) async {}

  @override
  Future<List<LeaderboardEntry>> fetchHistoricalLeaderboard(
    String date,
  ) async => [];

  @override
  Future<void> updateDisplayName(String displayName) async {}
}

Widget _wrap(_FakeRepository repo) => ProviderScope(
  overrides: [repositoryProvider.overrideWithValue(repo)],
  child: const MaterialApp(home: PowerupScreen()),
);

final powerup = InventoryItem(
  itemId: 'item-001',
  name: 'Point Boost',
  description: 'Boost your points by 7',
  type: ItemType.powerup,
  expiresAt: neverExpires,
);

final attack = InventoryItem(
  itemId: 'item-002',
  name: 'Point Drain',
  description: 'Drain a friend',
  type: ItemType.attack,
  expiresAt: neverExpires,
);

final friend = Friend(
  userId: 'me',
  friendId: 'friend-1',
  username: 'alice',
  displayName: 'Alice',
  createdAt: '2026-01-01',
);

void main() {
  group('PowerupsScreen', () {
    testWidgets('shows empty inventory message if inventory is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_FakeRepository()));
      await tester.pump();
      expect(find.text('No powerups available'), findsOneWidget);
    });

    testWidgets(
      'shows inventory item when the user has powerups in the inventory',
      (tester) async {
        await tester.pumpWidget(_wrap(_FakeRepository(inventory: [powerup])));
        await tester.pump();
        expect(find.text('Point Boost'), findsOneWidget);
        expect(find.text('Boost your points by 7'), findsOneWidget);
      },
    );

    testWidgets('pressing Use opens dialog', (tester) async {
      await tester.pumpWidget(_wrap(_FakeRepository(inventory: [powerup])));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Use'));
      await tester.pumpAndSettle();
      expect(find.text('Use on yourself?'), findsOneWidget);
    });

    testWidgets('attack item shows friend selector', (tester) async {
      await tester.pumpWidget(
        _wrap(_FakeRepository(inventory: [attack], friends: [friend])),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Use'));
      await tester.pumpAndSettle();
      expect(find.text('Target Friend'), findsOneWidget);
    });
  });
}
