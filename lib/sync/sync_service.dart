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
      // Non-fatal — submitSteps creates a minimal user record via UpdateCommand.
      // Fix: deploy lambda patch that omits null username from PutCommand.
      safePrint('upsertUser failed, continuing sync: $e');
    }
    await Future.wait([_syncSteps(), _syncLeaderboard()]);
  }

  Future<void> syncOnForeground() async {
    await Future.wait([_syncSteps(), _syncLeaderboard()]);
  }

  Future<void> _syncSteps() async {
    await _health.requestPermission();
    final steps = await _health.getTodaySteps();
    await _cloud.submitSteps(steps);
    await _repo.putSteps(steps);
  }

  Future<void> _syncLeaderboard() async {
    final entries = await _cloud.fetchLeaderboard();
    await _repo.pushLeaderboard(entries);
  }
}
