import '../models/avatar_upload_response.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/leaderboard_entry.dart';
import '../models/inventory_item.dart';
import '../models/use_item_result.dart';
import '../models/user_profile.dart';

abstract class AppRepository {
  Stream<List<LeaderboardEntry>> watchLeaderboard();
  Stream<List<InventoryItem>> watchInventory();
  Stream<int> watchStepCount();
  Stream<List<Friend>> watchFriends();
  Future<UserProfile> getCurrentUser();

  Future<void> updateDisplayName(String displayName);
  Future<void> putSteps(int stepCount);
  Future<UseItemResult> useItem(String itemId, String targetUserId);
  Future<void> addFriend(String username);
  Future<void> removeFriend(String friendId);
  Future<List<FriendRequest>> getFriendRequests();
  Future<void> acceptFriendRequest(String fromUserId);
  Future<void> declineFriendRequest(String fromUserId);
  Future<List<LeaderboardEntry>> fetchHistoricalLeaderboard(String date);
  Future<AvatarUploadResponse> getAvatarUploadUrl(String contentType);
  Future<void> updateAvatarUrl(String avatarUrl);
}
