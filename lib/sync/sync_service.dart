import 'package:amplify_flutter/amplify_flutter.dart' show safePrint;
import '../repository/cloud_repository.dart';
import '../repository/health_repository.dart';
import '../repository/sqf_repository.dart';

class SyncService {
  final HealthRepository _health;
  final CloudRepository _cloud;
  final SqfRepository _repo;

  SyncService({
    required HealthRepository health,
    required CloudRepository cloud,
    required SqfRepository repo,
  }) : _health = health,
       _cloud = cloud,
       _repo = repo;

  // Full sync on first login — registers the user profile then refreshes data
  Future<void> syncOnLogin() async {
    try {
      await _cloud.upsertUser();
    } catch (e) {
      safePrint('upsertUser failed, continuing sync: $e');
    }
    await _syncSteps().catchError((e) => safePrint('syncSteps failed: $e'));
    await Future.wait([
      _syncLeaderboard().catchError(
        (e) => safePrint('syncLeaderboard failed: $e'),
      ),
      _syncFriends().catchError((e) => safePrint('syncFriends failed: $e')),
      _syncInventory().catchError((e) => safePrint('syncInventory failed: $e')),
    ]);
  }

  Future<void> syncOnForeground() async {
    await _syncSteps().catchError((e) => safePrint('syncSteps failed: $e'));
    await Future.wait([
      _syncLeaderboard().catchError(
        (e) => safePrint('syncLeaderboard failed: $e'),
      ),
      _syncFriends().catchError((e) => safePrint('syncFriends failed: $e')),
      _syncInventory().catchError((e) => safePrint('syncInventory failed: $e')),
    ]);
  }

  Future<void> _syncSteps() async {
    int steps = 0;
    try {
      await _health.requestPermission().timeout(const Duration(seconds: 5));
      steps = await _health.getTodaySteps();
    } catch (e) {
      safePrint('Health read failed: $e');
    }
    await _cloud.submitSteps(steps);
    await _repo.putSteps(steps);
  }

  Future<void> _syncLeaderboard() async {
    final (:entries, :resetTimeUtc) = await _cloud.fetchTodayLeaderboard();
    await _repo.pushLeaderboard(entries, resetTimeUtc: resetTimeUtc);
  }

  Future<void> _syncFriends() async {
    final friends = await _cloud.fetchFriends();
    await _repo.pushFriends(friends);
  }

  Future<void> _syncInventory() async {
    final items = await _cloud.fetchInventory();
    await _repo.pushInventory(items);
  }
}
