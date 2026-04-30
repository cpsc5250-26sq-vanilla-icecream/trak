import 'package:flutter_test/flutter_test.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/repository/cloud_repository.dart';
import 'package:trak/repository/health_repository.dart';
import 'package:trak/repository/sqflite_app_repository.dart';
import 'package:trak/sync/sync_service.dart';

// ── fakes ──────────────────────────────────────────────────────────────────

class _FakeHealth extends HealthRepository {
  final int steps;
  _FakeHealth({this.steps = 1000});

  @override
  Future<void> requestPermission() async {}

  @override
  Future<int> getTodaySteps() async => steps;
}

class _FakeCloud extends CloudRepository {
  bool upsertCalled = false;
  bool upsertShouldThrow;
  int? submittedSteps;
  final List<LeaderboardEntry> leaderboard;

  _FakeCloud({this.leaderboard = const [], this.upsertShouldThrow = false});

  @override
  Future<void> upsertUser() async {
    upsertCalled = true;
    if (upsertShouldThrow) throw Exception('simulated upsert failure');
  }

  @override
  Future<void> submitSteps(int stepCount) async {
    submittedSteps = stepCount;
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard() async => leaderboard;
}

class _FakeRepo extends SqfliteAppRepository {
  int? lastSteps;
  List<LeaderboardEntry>? lastLeaderboard;

  @override
  Future<void> putSteps(int stepCount) async {
    lastSteps = stepCount;
  }

  @override
  Future<void> pushLeaderboard(List<LeaderboardEntry> entries) async {
    lastLeaderboard = entries;
  }
}

// ── helpers ─────────────────────────────────────────────────────────────────

const _entry = LeaderboardEntry(
  userId: 'u1',
  username: 'alice',
  totalPoints: 500,
  rank: 1,
);

SyncService _make({_FakeHealth? health, _FakeCloud? cloud, _FakeRepo? repo}) =>
    SyncService(
      health: health ?? _FakeHealth(),
      cloud: cloud ?? _FakeCloud(),
      repo: repo ?? _FakeRepo(),
    );

// ── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('SyncService.syncOnForeground', () {
    test('submits steps from health to cloud', () async {
      final health = _FakeHealth(steps: 7500);
      final cloud = _FakeCloud();
      await _make(health: health, cloud: cloud).syncOnForeground();
      expect(cloud.submittedSteps, 7500);
    });

    test('writes steps from health to local repo', () async {
      final health = _FakeHealth(steps: 3200);
      final repo = _FakeRepo();
      await _make(health: health, repo: repo).syncOnForeground();
      expect(repo.lastSteps, 3200);
    });

    test('writes leaderboard from cloud to local repo', () async {
      final cloud = _FakeCloud(leaderboard: [_entry]);
      final repo = _FakeRepo();
      await _make(cloud: cloud, repo: repo).syncOnForeground();
      expect(repo.lastLeaderboard, [_entry]);
    });

    test('does not call upsertUser', () async {
      final cloud = _FakeCloud();
      await _make(cloud: cloud).syncOnForeground();
      expect(cloud.upsertCalled, isFalse);
    });
  });

  group('SyncService.syncOnLogin', () {
    test('calls upsertUser', () async {
      final cloud = _FakeCloud();
      await _make(cloud: cloud).syncOnLogin();
      expect(cloud.upsertCalled, isTrue);
    });

    test('continues sync even when upsertUser throws', () async {
      final cloud = _FakeCloud(upsertShouldThrow: true, leaderboard: [_entry]);
      final repo = _FakeRepo();
      await _make(cloud: cloud, repo: repo).syncOnLogin();
      // steps and leaderboard should still be written
      expect(repo.lastSteps, isNotNull);
      expect(repo.lastLeaderboard, isNotNull);
    });

    test('submits steps after upsertUser succeeds', () async {
      final health = _FakeHealth(steps: 500);
      final cloud = _FakeCloud();
      await _make(health: health, cloud: cloud).syncOnLogin();
      expect(cloud.submittedSteps, 500);
    });
  });
}
