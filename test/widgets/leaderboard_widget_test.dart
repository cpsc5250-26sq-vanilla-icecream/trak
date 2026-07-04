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
import 'package:trak/widgets/leaderboard_widget.dart';

class _FakeRepo implements AppRepository {
  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() => Stream.value([]);
  @override
  Stream<List<InventoryItem>> watchInventory() => const Stream.empty();
  @override
  Stream<int> watchStepCount() => const Stream.empty();
  @override
  Stream<List<Friend>> watchFriends() => const Stream.empty();
  @override
  Stream<DateTime?> watchResetTime() => const Stream.empty();
  @override
  Future<UserProfile> getCurrentUser() async =>
      const UserProfile(userId: 'me', username: 'tester', displayName: '');
  @override
  Future<List<LeaderboardEntry>> fetchHistoricalLeaderboard(
    String date,
  ) async => [];
  @override
  Future<void> updateDisplayName(String d) async {}
  @override
  Future<void> putSteps(int s) async {}
  @override
  Future<void> addFriend(String u) async {}
  @override
  Future<void> removeFriend(String f) async {}
  @override
  Future<List<FriendRequest>> getFriendRequests() async => [];
  @override
  Future<void> acceptFriendRequest(String f) async {}
  @override
  Future<void> declineFriendRequest(String f) async {}
  @override
  Future<UseItemResult> useItem(String i, String t) async =>
      const UseItemResult.success();
  @override
  Future<AvatarUploadResponse> getAvatarUploadUrl(String contentType) =>
      throw UnimplementedError();
  @override
  Future<void> updateAvatarUrl(String avatarUrl) async {}
}

Widget _wrapRow(LeaderboardRow row) => MaterialApp(home: Scaffold(body: row));

Widget _wrapWidget({VoidCallback? onHistoryTap}) => ProviderScope(
  overrides: [repositoryProvider.overrideWithValue(_FakeRepo())],
  child: MaterialApp(
    home: Scaffold(body: LeaderboardWidget(onHistoryTap: onHistoryTap)),
  ),
);

void main() {
  group('LeaderboardRow display name fallback', () {
    testWidgets('shows username when displayName is null', (tester) async {
      await tester.pumpWidget(
        _wrapRow(
          const LeaderboardRow(
            entry: LeaderboardEntry(
              userId: 'u1',
              username: 'alice',
              totalPoints: 0,
              rank: 1,
            ),
            isCurrentUser: false,
          ),
        ),
      );
      expect(find.text('alice'), findsOneWidget);
    });

    testWidgets('shows username when displayName is empty', (tester) async {
      await tester.pumpWidget(
        _wrapRow(
          const LeaderboardRow(
            entry: LeaderboardEntry(
              userId: 'u1',
              username: 'alice',
              displayName: '',
              totalPoints: 0,
              rank: 1,
            ),
            isCurrentUser: false,
          ),
        ),
      );
      expect(find.text('alice'), findsOneWidget);
    });

    testWidgets('shows displayName when non-empty', (tester) async {
      await tester.pumpWidget(
        _wrapRow(
          const LeaderboardRow(
            entry: LeaderboardEntry(
              userId: 'u1',
              username: 'alice',
              displayName: 'Alice Smith',
              totalPoints: 0,
              rank: 1,
            ),
            isCurrentUser: false,
          ),
        ),
      );
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('alice'), findsNothing);
    });
  });

  group('LeaderboardWidget history button', () {
    testWidgets('shows history icon when onHistoryTap is provided', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWidget(onHistoryTap: () {}));
      await tester.pump();
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('hides history icon when onHistoryTap is null', (tester) async {
      await tester.pumpWidget(_wrapWidget());
      await tester.pump();
      expect(find.byIcon(Icons.history), findsNothing);
    });
  });
}
