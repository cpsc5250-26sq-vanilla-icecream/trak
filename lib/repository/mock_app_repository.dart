import 'dart:async';
import 'app_repository.dart';
import '../models/leaderboard_entry.dart';
import '../models/inventory_item.dart';
import '../models/use_item_result.dart';
import '../models/user_profile.dart';

class MockAppRepository implements AppRepository {
  static const _currentUserId = 'user-001';

  final _leaderboardController =
      StreamController<List<LeaderboardEntry>>.broadcast();
  final _inventoryController =
      StreamController<List<InventoryItem>>.broadcast();
  final _stepController = StreamController<int>.broadcast();

  final _tickPayload = 12;
  var _steps = 4200;
  var _leaderboard = _initialLeaderboard();
  var _inventory = _initialInventory();

  late final Timer _tickTimer;

  MockAppRepository() {
    // Simulate a pedometer ticking every 3 seconds.
    // Obviously way fast for an actual smartphone pedometer
    // (updates every ~10 min), but this is fast enough to see
    // changes in real-time for testing.
    _tickTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _steps += _tickPayload;
      _stepController.add(_steps);

      _leaderboard = _rerank(
        _leaderboard.map((e) {
          if (e.userId == _currentUserId) {
            return LeaderboardEntry(
              userId: e.userId,
              username: e.username,
              avatarUrl: e.avatarUrl,
              totalPoints: e.totalPoints + _tickPayload,
              rank: e.rank,
            );
          }
          return e;
        }).toList(),
      );
      _leaderboardController.add(_leaderboard);
    });
  }

  // Each watch method yields the current snapshot first, then live updates.
  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() async* {
    yield _leaderboard;
    yield* _leaderboardController.stream;
  }

  @override
  Stream<List<InventoryItem>> watchInventory() async* {
    yield _inventory;
    yield* _inventoryController.stream;
  }

  @override
  Stream<int> watchStepCount() async* {
    yield _steps;
    yield* _stepController.stream;
  }

  @override
  Future<UserProfile> getCurrentUser() async => const UserProfile(
    userId: _currentUserId,
    username: 'you',
    displayName: 'You',
  );

  @override
  Future<void> putSteps(int stepCount) async {
    _steps = stepCount;
    _stepController.add(_steps);
  }

  @override
  Future<UseItemResult> useItem(String itemId, String targetUserId) async {
    final item = _inventory.where((i) => i.itemId == itemId).firstOrNull;
    if (item == null) return const UseItemResult.failure('Item not found');

    _inventory = _inventory.where((i) => i.itemId != itemId).toList();
    _inventoryController.add(_inventory);

    _leaderboard = _rerank(
      _leaderboard.map((e) {
        if (e.userId == targetUserId) {
          final delta = item.type == ItemType.powerup ? 250 : -250;
          return LeaderboardEntry(
            userId: e.userId,
            username: e.username,
            avatarUrl: e.avatarUrl,
            totalPoints: (e.totalPoints + delta).clamp(0, 999999),
            rank: e.rank,
          );
        }
        return e;
      }).toList(),
    );
    _leaderboardController.add(_leaderboard);

    return const UseItemResult.success();
  }

  @override
  Future<void> addFriend(String targetUserId) async {}

  @override
  Future<void> removeFriend(String targetUserId) async {
    _leaderboard = _leaderboard.where((e) => e.userId != targetUserId).toList();
    _leaderboardController.add(_leaderboard);
  }

  void dispose() {
    _tickTimer.cancel();
    _leaderboardController.close();
    _inventoryController.close();
    _stepController.close();
  }

  static List<LeaderboardEntry> _initialLeaderboard() => _rerank([
    const LeaderboardEntry(
      userId: _currentUserId,
      username: 'you',
      totalPoints: 1840,
      rank: 0,
    ),
    const LeaderboardEntry(
      userId: 'user-002',
      username: 'alex_walks',
      totalPoints: 3120,
      rank: 0,
    ),
    const LeaderboardEntry(
      userId: 'user-003',
      username: 'steph_steps',
      totalPoints: 2750,
      rank: 0,
    ),
    const LeaderboardEntry(
      userId: 'user-004',
      username: 'mike_miles',
      totalPoints: 980,
      rank: 0,
    ),
  ]);

  static List<InventoryItem> _initialInventory() => const [
    InventoryItem(
      itemId: 'item-001',
      name: 'Double Points',
      description: 'Doubles your points for the next 30 minutes.',
      type: ItemType.powerup,
    ),
    InventoryItem(
      itemId: 'item-002',
      name: 'Step Drain',
      description: "Removes 250 points from a friend's total.",
      type: ItemType.attack,
    ),
  ];

  static List<LeaderboardEntry> _rerank(List<LeaderboardEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return sorted
        .asMap()
        .entries
        .map(
          (e) => LeaderboardEntry(
            userId: e.value.userId,
            username: e.value.username,
            avatarUrl: e.value.avatarUrl,
            totalPoints: e.value.totalPoints,
            rank: e.key + 1,
          ),
        )
        .toList();
  }
}
