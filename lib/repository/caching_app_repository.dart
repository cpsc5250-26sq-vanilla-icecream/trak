import 'package:amplify_flutter/amplify_flutter.dart' show safePrint;

import '../models/avatar_upload_response.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/inventory_item.dart';
import '../models/leaderboard_entry.dart';
import '../models/use_item_result.dart';
import '../models/user_profile.dart';
import 'app_repository.dart';
import 'cloud_repository.dart';
import 'sqf_repository.dart';

class CachingAppRepository implements AppRepository {
  final CloudRepository _cloud;
  final SqfRepository _cache;

  CachingAppRepository({
    required CloudRepository cloud,
    required SqfRepository cache,
  }) : _cloud = cloud,
       _cache = cache;

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() =>
      _cache.watchLeaderboard();

  @override
  Stream<List<InventoryItem>> watchInventory() => _cache.watchInventory();

  @override
  Stream<int> watchStepCount() => _cache.watchStepCount();

  @override
  Stream<List<Friend>> watchFriends() => _cache.watchFriends();

  @override
  Future<UserProfile> getCurrentUser() => _cloud.getCurrentUser();

  @override
  Future<void> updateDisplayName(String displayName) =>
      _cloud.updateDisplayName(displayName);

  @override
  Future<void> putSteps(int stepCount) async {
    await _cloud.submitSteps(stepCount);
    await _cache.putSteps(stepCount);
  }

  @override
  Future<void> addFriend(String username) async {
    await _cloud.addFriend(username);
    final results = await Future.wait([
      _cloud.fetchFriends(),
      _cloud.fetchTodayLeaderboard(),
    ]);
    await _cache.pushFriends(results[0] as List<Friend>);
    final lb =
        results[1] as ({List<LeaderboardEntry> entries, int resetTimeUtc});
    await _cache.pushLeaderboard(lb.entries, resetTimeUtc: lb.resetTimeUtc);
  }

  @override
  Future<void> removeFriend(String friendId) async {
    await _cloud.removeFriend(friendId);
    final results = await Future.wait([
      _cloud.fetchFriends(),
      _cloud.fetchTodayLeaderboard(),
    ]);
    await _cache.pushFriends(results[0] as List<Friend>);
    final lb =
        results[1] as ({List<LeaderboardEntry> entries, int resetTimeUtc});
    await _cache.pushLeaderboard(lb.entries, resetTimeUtc: lb.resetTimeUtc);
  }

  @override
  Future<UseItemResult> useItem(String itemId, String targetUserId) async {
    final result = await _cloud.useItem(itemId, targetUserId);
    if (!result.success) return result;
    await Future.wait([
      _cloud
          .fetchInventory()
          .then(_cache.pushInventory)
          .catchError(
            (e) => safePrint('useItem: inventory refresh failed: $e'),
          ),
      _cloud
          .fetchTodayLeaderboard()
          .then(
            (lb) => _cache.pushLeaderboard(
              lb.entries,
              resetTimeUtc: lb.resetTimeUtc,
            ),
          )
          .catchError(
            (e) => safePrint('useItem: leaderboard refresh failed: $e'),
          ),
    ]);
    return result;
  }

  @override
  Future<List<FriendRequest>> getFriendRequests() =>
      _cloud.fetchFriendRequests();

  @override
  Future<void> acceptFriendRequest(String fromUserId) async {
    await _cloud.acceptFriendRequest(fromUserId);
    final results = await Future.wait([
      _cloud.fetchFriends(),
      _cloud.fetchTodayLeaderboard(),
    ]);
    await _cache.pushFriends(results[0] as List<Friend>);
    final lb =
        results[1] as ({List<LeaderboardEntry> entries, int resetTimeUtc});
    await _cache.pushLeaderboard(lb.entries, resetTimeUtc: lb.resetTimeUtc);
  }

  @override
  Future<void> declineFriendRequest(String fromUserId) =>
      _cloud.declineFriendRequest(fromUserId);

  @override
  Future<List<LeaderboardEntry>> fetchHistoricalLeaderboard(String date) =>
      _cloud.fetchLeaderboard(date: date);

  @override
  Future<AvatarUploadResponse> getAvatarUploadUrl(String contentType) =>
      _cloud.getAvatarUploadUrl(contentType);

  @override
  Future<void> updateAvatarUrl(String avatarUrl) =>
      _cloud.updateAvatarUrl(avatarUrl);
}
