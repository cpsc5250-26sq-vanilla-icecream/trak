import 'dart:async';
import 'package:trak/models/friend.dart';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';
import '../database/app_database.dart';

class SqfRepository {
  final AppDatabase _db;

  SqfRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;
  final _stepsController = StreamController<int>.broadcast();
  final _leaderboardController =
      StreamController<List<LeaderboardEntry>>.broadcast();
  final _inventoryController =
      StreamController<List<InventoryItem>>.broadcast();
  final _friendsController = StreamController<List<Friend>>.broadcast();

  String _today() => DateTime.now().toIso8601String().split('T').first;

  Future<void> _notify() async {
    final steps = await _db.getCurrentSteps(date: _today());
    _stepsController.add(steps ?? 0);
  }

  Future<void> pushLeaderboard(
    List<LeaderboardEntry> entries, {
    required int resetTimeUtc,
    String leaderboardId = AppDatabase.defaultLeaderboardId,
  }) async {
    await _db.replaceLeaderboard(entries);
    await _db.saveResetTimeUtc(leaderboardId, resetTimeUtc);
    await _db.updateSyncTime(AppDatabase.syncKeyLeaderboard);
    _leaderboardController.add(entries);
  }

  Future<void> putSteps(int stepCount) async {
    await _db.upsertSteps(date: _today(), stepCount: stepCount);
    await _db.updateSyncTime(AppDatabase.syncKeySteps);
    await _notify();
  }

  Future<void> pushInventory(List<InventoryItem> items) async {
    await _db.replaceInventory(items);
    await _db.updateSyncTime(AppDatabase.syncKeyInventory);
    _inventoryController.add(items);
  }

  Future<void> pushFriends(List<Friend> friends) async {
    await _db.replaceFriends(friends);
    await _db.updateSyncTime(AppDatabase.syncKeyFriends);
    _friendsController.add(friends);
  }

  Stream<List<LeaderboardEntry>> watchLeaderboard() {
    _db.getLeaderboard().then((entries) {
      if (!_leaderboardController.isClosed) _leaderboardController.add(entries);
    });
    return _leaderboardController.stream;
  }

  Stream<int> watchStepCount() {
    _notify();
    return _stepsController.stream;
  }

  Stream<List<InventoryItem>> watchInventory() {
    _db.getInventory().then((items) {
      if (!_inventoryController.isClosed) _inventoryController.add(items);
    });
    return _inventoryController.stream;
  }

  Stream<List<Friend>> watchFriends() {
    _db.getFriends().then((friends) {
      if (!_friendsController.isClosed) _friendsController.add(friends);
    });
    return _friendsController.stream;
  }

  void dispose() {
    _stepsController.close();
    _leaderboardController.close();
    _inventoryController.close();
    _friendsController.close();
  }
}
