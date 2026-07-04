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
import 'package:trak/screens/historical_leaderboard_screen.dart';

class _FakeRepo implements AppRepository {
  final List<LeaderboardEntry> entries;
  const _FakeRepo({this.entries = const []});

  @override
  Future<List<LeaderboardEntry>> fetchHistoricalLeaderboard(
    String date,
  ) async => entries;

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
  Future<UserProfile> getCurrentUser() async => const UserProfile(
    userId: 'me',
    username: 'tester',
    displayName: 'Tester',
  );
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

Widget _wrap(AppRepository repo) => ProviderScope(
  overrides: [repositoryProvider.overrideWithValue(repo)],
  child: const MaterialApp(home: HistoricalLeaderboardScreen()),
);

void main() {
  group('HistoricalLeaderboardScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(_wrap(const _FakeRepo()));
      await tester.pump();
      expect(find.text('Past Leaderboards'), findsOneWidget);
    });

    testWidgets('shows empty state when no snapshot exists', (tester) async {
      await tester.pumpWidget(_wrap(const _FakeRepo()));
      await tester.pump();
      expect(find.text('No leaderboard for this day.'), findsOneWidget);
    });

    testWidgets('shows entry display name when available', (tester) async {
      final repo = _FakeRepo(
        entries: [
          const LeaderboardEntry(
            userId: 'u1',
            username: 'alice',
            displayName: 'Alice Smith',
            totalPoints: 800,
            rank: 1,
          ),
        ],
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pump();
      expect(find.text('Alice Smith'), findsOneWidget);
    });

    testWidgets('falls back to username when displayName is null', (
      tester,
    ) async {
      final repo = _FakeRepo(
        entries: [
          const LeaderboardEntry(
            userId: 'u2',
            username: 'bob',
            totalPoints: 400,
            rank: 1,
          ),
        ],
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pump();
      expect(find.text('bob'), findsOneWidget);
    });
  });
}
