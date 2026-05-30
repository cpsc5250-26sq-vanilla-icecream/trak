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
  Future<void> putSteps(int stepCount) async {
    await _cloud.submitSteps(stepCount);
    await _cache.putSteps(stepCount);
  }

  @override
  Future<void> addFriend(String username) async {
    await _cloud.addFriend(username);
    final results = await Future.wait([
      _cloud.fetchFriends(),
      _cloud.fetchLeaderboard(),
    ]);
    await _cache.pushFriends(results[0] as List<Friend>);
    await _cache.pushLeaderboard(results[1] as List<LeaderboardEntry>);
  }

  @override
  Future<void> removeFriend(String friendId) async {
    await _cloud.removeFriend(friendId);
    final results = await Future.wait([
      _cloud.fetchFriends(),
      _cloud.fetchLeaderboard(),
    ]);
    await _cache.pushFriends(results[0] as List<Friend>);
    await _cache.pushLeaderboard(results[1] as List<LeaderboardEntry>);
  }

  @override
  Future<UseItemResult> useItem(String itemId, String targetUserId) {
    // TODO: implement useItem
    throw UnimplementedError();
  }

  @override
  Future<List<FriendRequest>> getFriendRequests() =>
      _cloud.fetchFriendRequests();

  @override
  Future<void> acceptFriendRequest(String fromUserId) async {
    await _cloud.acceptFriendRequest(fromUserId);
    final results = await Future.wait([
      _cloud.fetchFriends(),
      _cloud.fetchLeaderboard(),
    ]);
    await _cache.pushFriends(results[0] as List<Friend>);
    await _cache.pushLeaderboard(results[1] as List<LeaderboardEntry>);
  }

  @override
  Future<void> declineFriendRequest(String fromUserId) =>
      _cloud.declineFriendRequest(fromUserId);

  @override
  Future<List<LeaderboardEntry>> fetchHistoricalLeaderboard(String date) =>
      _cloud.fetchLeaderboard(date: date);
}
