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
  Future<void> addFriend(String username);
  Future<void> removeFriend(String friendId);
  Stream<List<Friend>> watchFriends();
}
