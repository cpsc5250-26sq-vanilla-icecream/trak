import '../models/friend.dart';
import '../models/leaderboard_entry.dart';
import '../models/inventory_item.dart';
import '../models/use_item_result.dart';
import '../models/user_profile.dart';

abstract class AppRepository {
  Stream<List<LeaderboardEntry>> watchLeaderboard();
  Stream<List<InventoryItem>> watchInventory();
  Stream<int> watchStepCount();
  Future<UserProfile> getCurrentUser();

  Future<void> putSteps(int stepCount);
  Future<UseItemResult> useItem(String itemId, String targetUserId);
  Future<void> addFriend(String targetUserId);
  Future<void> removeFriend(String targetUserId);
  Future<List<Friend>> getFriends();
}
