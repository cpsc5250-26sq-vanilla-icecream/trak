import 'dart:async';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/models/use_item_result.dart';
import 'package:trak/models/user_profile.dart';
import 'package:trak/repository/app_repository.dart';
import '../database/app_database.dart';

class SqfliteAppRepository implements AppRepository {
  final AppDatabase _db = AppDatabase.instance;
  final _stepsController = StreamController<int>.broadcast();
  final _leaderboardController =
      StreamController<List<LeaderboardEntry>>.broadcast();

  // TODO: replace with real user ID once auth is wired up
  final String currentUserId = "";

  String _today() => DateTime.now().toIso8601String().split('T').first;

  Future<void> _notify() async {
    final steps = await _db.getCurrentSteps(date: _today());
    _stepsController.add(steps ?? 0);
  }

  Future<void> pushLeaderboard(List<LeaderboardEntry> entries) async {
    await _db.replaceLeaderboard(entries);
    await _db.updateSyncTime(AppDatabase.syncKeyLeaderboard);
    _leaderboardController.add(entries);
  }

  void dispose() {
    _stepsController.close();
    _leaderboardController.close();
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
    await _db.upsertSteps(date: _today(), stepCount: stepCount);
    await _db.updateSyncTime(AppDatabase.syncKeySteps);
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
    _db.getLeaderboard().then((entries) {
      if (!_leaderboardController.isClosed) _leaderboardController.add(entries);
    });
    return _leaderboardController.stream;
  }

  @override
  Stream<int> watchStepCount() {
    _notify();
    return _stepsController.stream;
  }
}
