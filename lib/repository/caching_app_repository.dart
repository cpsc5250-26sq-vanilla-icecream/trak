import '../models/Friend.dart';
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
  Future<UserProfile> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<void> putSteps(int stepCount) async {
    await _cloud.submitSteps(stepCount);
    await _cache.putSteps(stepCount);
  }

  @override
  Future<void> addFriend(String targetUserId) {
    // TODO: implement addFriend
    throw UnimplementedError();
  }

  @override
  Future<void> removeFriend(String targetUserId) {
    // TODO: implement removeFriend
    throw UnimplementedError();
  }

  @override
  Future<UseItemResult> useItem(String itemId, String targetUserId) {
    // TODO: implement useItem
    throw UnimplementedError();
  }

  @override
  Future<List<Friend>> getFriends() {
    // TODO: Implement write-through caching.
    // 1. Read friends from local cache (SqfRepository).
    // 2. Sync with cloud in background.
    // 3. Persist cloud response back into cache.
    return _cloud.fetchFriends();
  }
}
