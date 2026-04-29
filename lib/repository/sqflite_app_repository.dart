import 'dart:async';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/models/use_item_result.dart';
import 'package:trak/models/user_profile.dart';
import 'package:trak/repository/app_repository.dart';
import '../database/app_database.dart';
import 'health_repository.dart';

class SqfliteAppRepository implements AppRepository {
  final AppDatabase db = AppDatabase.instance;
  final HealthRepository health = HealthRepository();

  // Todo: Get user AUTH
  final String currentUserId = "";
  final _stepsController = StreamController<int>.broadcast();

  // Get Today's Date
  String _today() => DateTime.now().toIso8601String().split('T').first;

  // Update Widgets Through Stream Controller
  Future<void> _notify() async {
    final steps = await db.getCurrentSteps(
      userId: currentUserId,
      date: _today(),
    );
    _stepsController.add(steps ?? 0);
  }

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
  Future<void> putSteps(int stepCount) async {
    await health.requestPermission();
    final steps = await health.getTodaySteps();

    await db.upsertSteps(
      userId: currentUserId,
      date: _today(),
      stepCount: steps,
    );

    await _notify();
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
    _notify();
    return _stepsController.stream;
  }
}
