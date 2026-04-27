import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/models/use_item_result.dart';
import 'package:trak/models/user_profile.dart';
import 'package:trak/repository/app_repository.dart';
import '../database/app_database.dart';

class SqfliteAppRepository implements AppRepository{
  final AppDatabase _db = AppDatabase.instance;
  @override
  Future<void> addFriend(String targetUserId) {
    // TODO: implement addFriend
    throw UnimplementedError();
  }

  @override
  Future<UserProfile> getCurrentUser() {
    // TODO: implement getCurrentUser
    throw UnimplementedError();
  }

  @override
  Future<void> putSteps(int stepCount) {
    // TODO: implement putSteps
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
  Stream<List<InventoryItem>> watchInventory() {
    // TODO: implement watchInventory
    throw UnimplementedError();
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() {
    // TODO: implement watchLeaderboard
    throw UnimplementedError();
  }

  @override
  Stream<int> watchStepCount() {
    // TODO: implement watchStepCount
    throw UnimplementedError();
  }

}