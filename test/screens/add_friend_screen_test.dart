import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/models/avatar_upload_response.dart';
import 'package:trak/models/friend.dart';
import 'package:trak/models/friend_request.dart';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/models/use_item_result.dart';
import 'package:trak/models/user_profile.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/repository/app_repository.dart';
import 'package:trak/screens/add_friend_screen.dart';

class _FakeRepository implements AppRepository {
  bool addFriendShouldThrow;
  String? lastAddedFriend;
  String? acceptedFromUserId;
  String? declinedFromUserId;
  String? removedFriendId;
  final List<FriendRequest> pendingRequests;
  final List<Friend> friends;

  _FakeRepository({
    this.addFriendShouldThrow = false,
    this.pendingRequests = const [],
    this.friends = const [],
  });

  @override
  Future<void> addFriend(String username) async {
    if (addFriendShouldThrow) throw Exception('User not found');
    lastAddedFriend = username;
  }

  @override
  Future<List<FriendRequest>> getFriendRequests() async => pendingRequests;

  @override
  Future<void> acceptFriendRequest(String fromUserId) async {
    acceptedFromUserId = fromUserId;
  }

  @override
  Future<void> declineFriendRequest(String fromUserId) async {
    declinedFromUserId = fromUserId;
  }

  @override
  Stream<List<Friend>> watchFriends() => Stream.value(friends);

  @override
  Stream<DateTime?> watchResetTime() => const Stream.empty();

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
  Future<void> updateDisplayName(String displayName) async {}
  @override
  Future<void> putSteps(int stepCount) async {}
  @override
  Future<UseItemResult> useItem(String itemId, String targetUserId) async =>
      const UseItemResult.success();
  @override
  Future<void> removeFriend(String friendId) async {
    removedFriendId = friendId;
  }

  @override
  Future<List<LeaderboardEntry>> fetchHistoricalLeaderboard(
    String date,
  ) async => [];

  @override
  Future<AvatarUploadResponse> getAvatarUploadUrl(String contentType) async {
    return AvatarUploadResponse(
      uploadUrl: 'https://example.com/upload',
      publicUrl: 'https://example.com/avatar.jpg',
      contentType: contentType,
    );
  }

  @override
  Future<void> updateAvatarUrl(String avatarUrl) async {}
}

Widget _wrap(_FakeRepository repo) => ProviderScope(
  overrides: [repositoryProvider.overrideWithValue(repo)],
  child: const MaterialApp(home: AddFriendScreen()),
);

// pump once for initState microtask, once more to resolve async providers
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

final _requestWithDisplayName = FriendRequest(
  fromUserId: 'user-111',
  fromUsername: 'alice',
  fromDisplayName: 'Alice Smith',
  createdAt: '2026-05-28T10:00:00Z',
);

final _requestNoDisplayName = FriendRequest(
  fromUserId: 'user-222',
  fromUsername: 'bob',
  createdAt: '2026-05-28T10:00:00Z',
);

final _friendWithDisplayName = Friend(
  userId: 'me',
  friendId: 'friend-001',
  username: 'carol',
  displayName: 'Carol Chen',
  createdAt: '2026-05-01T00:00:00Z',
);

final _friendNoDisplayName = Friend(
  userId: 'me',
  friendId: 'friend-002',
  username: 'dave',
  createdAt: '2026-05-01T00:00:00Z',
);

void main() {
  group('AddFriendScreen — send request', () {
    late _FakeRepository repo;

    setUp(() => repo = _FakeRepository());

    testWidgets('renders text field and Send Request button', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send Request'), findsOneWidget);
    });

    testWidgets('shows Add Friend in app bar', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      expect(find.widgetWithText(AppBar, 'Add Friend'), findsOneWidget);
    });

    testWidgets('empty submit does not call repository', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      await tester.tap(find.widgetWithText(FilledButton, 'Send Request'));
      await tester.pump();
      expect(repo.lastAddedFriend, isNull);
    });

    testWidgets('successful send shows confirmation message', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.tap(find.widgetWithText(FilledButton, 'Send Request'));
      await tester.pump();
      expect(find.text('Request sent to alice!'), findsOneWidget);
      expect(repo.lastAddedFriend, 'alice');
    });

    testWidgets('successful send clears text field', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.tap(find.widgetWithText(FilledButton, 'Send Request'));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'alice'), findsNothing);
    });

    testWidgets('failed send shows error message', (tester) async {
      repo = _FakeRepository(addFriendShouldThrow: true);
      await tester.pumpWidget(_wrap(repo));
      await tester.enterText(find.byType(TextField), 'ghost');
      await tester.tap(find.widgetWithText(FilledButton, 'Send Request'));
      await tester.pump();
      expect(find.textContaining('User not found'), findsOneWidget);
    });

    testWidgets('submit via keyboard triggers send', (tester) async {
      await tester.pumpWidget(_wrap(repo));
      await tester.enterText(find.byType(TextField), 'bob');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.lastAddedFriend, 'bob');
    });
  });

  group('AddFriendScreen — pending requests', () {
    testWidgets('shows no pending requests when list is empty', (tester) async {
      await tester.pumpWidget(_wrap(_FakeRepository()));
      await _settle(tester);
      expect(find.text('No pending requests'), findsOneWidget);
    });

    testWidgets('shows display name and username for a request', (
      tester,
    ) async {
      final repo = _FakeRepository(pendingRequests: [_requestWithDisplayName]);
      await tester.pumpWidget(_wrap(repo));
      await _settle(tester);
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('@alice'), findsOneWidget);
    });

    testWidgets('falls back to username as title when no display name', (
      tester,
    ) async {
      final repo = _FakeRepository(pendingRequests: [_requestNoDisplayName]);
      await tester.pumpWidget(_wrap(repo));
      await _settle(tester);
      expect(find.text('bob'), findsOneWidget);
      expect(find.text('@bob'), findsOneWidget);
    });

    testWidgets('accept button calls acceptFriendRequest with correct userId', (
      tester,
    ) async {
      final repo = _FakeRepository(pendingRequests: [_requestWithDisplayName]);
      await tester.pumpWidget(_wrap(repo));
      await _settle(tester);
      await tester.tap(find.byTooltip('Accept'));
      await tester.pump();
      expect(repo.acceptedFromUserId, 'user-111');
    });

    testWidgets(
      'decline button calls declineFriendRequest with correct userId',
      (tester) async {
        final repo = _FakeRepository(
          pendingRequests: [_requestWithDisplayName],
        );
        await tester.pumpWidget(_wrap(repo));
        await _settle(tester);
        await tester.tap(find.byTooltip('Decline'));
        await tester.pump();
        expect(repo.declinedFromUserId, 'user-111');
      },
    );
  });

  group('AddFriendScreen — friends list', () {
    testWidgets('shows empty state when no friends', (tester) async {
      await tester.pumpWidget(_wrap(_FakeRepository()));
      await _settle(tester);
      expect(find.text('No friends yet :('), findsOneWidget);
    });

    testWidgets('shows friend display name and username', (tester) async {
      final repo = _FakeRepository(friends: [_friendWithDisplayName]);
      await tester.pumpWidget(_wrap(repo));
      await _settle(tester);
      expect(find.text('Carol Chen'), findsOneWidget);
      expect(find.text('@carol'), findsOneWidget);
    });

    testWidgets('falls back to username as title when no display name', (
      tester,
    ) async {
      final repo = _FakeRepository(friends: [_friendNoDisplayName]);
      await tester.pumpWidget(_wrap(repo));
      await _settle(tester);
      expect(find.text('dave'), findsOneWidget);
    });

    testWidgets('remove button shows confirmation dialog', (tester) async {
      final repo = _FakeRepository(friends: [_friendWithDisplayName]);
      await tester.pumpWidget(_wrap(repo));
      await _settle(tester);
      await tester.tap(find.byTooltip('Remove friend'));
      await tester.pumpAndSettle();
      expect(find.text('Remove friend?'), findsOneWidget);
    });

    testWidgets('confirming removal calls removeFriend', (tester) async {
      final repo = _FakeRepository(friends: [_friendWithDisplayName]);
      await tester.pumpWidget(_wrap(repo));
      await _settle(tester);
      await tester.tap(find.byTooltip('Remove friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Remove'));
      await tester.pump();
      expect(repo.removedFriendId, 'friend-001');
    });

    testWidgets('cancelling removal does not call removeFriend', (
      tester,
    ) async {
      final repo = _FakeRepository(friends: [_friendWithDisplayName]);
      await tester.pumpWidget(_wrap(repo));
      await _settle(tester);
      await tester.tap(find.byTooltip('Remove friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump();
      expect(repo.removedFriendId, isNull);
    });
  });
}
