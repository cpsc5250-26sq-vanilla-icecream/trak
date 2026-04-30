import 'dart:async';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';
import '../database/app_database.dart';

class SqfRepository {
  final AppDatabase _db = AppDatabase.instance;
  final _stepsController = StreamController<int>.broadcast();
  final _leaderboardController =
      StreamController<List<LeaderboardEntry>>.broadcast();

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

  Future<void> putSteps(int stepCount) async {
    await _db.upsertSteps(date: _today(), stepCount: stepCount);
    await _db.updateSyncTime(AppDatabase.syncKeySteps);
    await _notify();
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
    // TODO: implement watchInventory
    throw UnimplementedError();
  }

  void dispose() {
    _stepsController.close();
    _leaderboardController.close();
  }
}
