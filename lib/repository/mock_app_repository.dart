import 'dart:async';
import 'dart:math';
import 'package:trak/models/avatar_upload_response.dart';

import '../models/friend.dart';
import '../models/friend_request.dart';
import '../utils/points_utils.dart';
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
  final _friendsController = StreamController<List<Friend>>.broadcast();

  final _tickPayload = 12;
  var _steps = 4200;
  String? _avatarUrl;
  var _leaderboard = _initialLeaderboard();
  var _inventory = _initialInventory();
  var _friends = _initialFriends();
  var _pendingRequests = _initialFriendRequests();

  late final Timer _tickTimer;

  MockAppRepository() {
    // Simulate a pedometer ticking every 3 seconds.
    // Obviously way fast for an actual smartphone pedometer
    // (updates every ~10 min), but this is fast enough to see
    // changes in real-time for testing.
    _tickTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final pointsDelta =
          stepsToPoints(_steps + _tickPayload) - stepsToPoints(_steps);
      _steps += _tickPayload;
      _stepController.add(_steps);

      _leaderboard = _rerank(
        _leaderboard.map((e) {
          if (e.userId == _currentUserId) {
            return LeaderboardEntry(
              userId: e.userId,
              username: e.username,
              avatarUrl: e.avatarUrl,
              totalPoints: e.totalPoints + pointsDelta,
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
  Future<UserProfile> getCurrentUser() async => UserProfile(
    userId: _currentUserId,
    username: 'you',
    displayName: 'You',
    avatarUrl: _avatarUrl,
  );

  @override
  Future<void> updateDisplayName(String displayName) async {}

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
          final delta = item.type == ItemType.powerup ? 7 : -7;
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
  Future<void> addFriend(String targetUserId) async {
    final newEntry = LeaderboardEntry(
      userId: targetUserId,
      username: targetUserId,
      totalPoints: Random().nextInt(3000) + 500,
      rank: 0,
    );
    _leaderboard = _rerank([..._leaderboard, newEntry]);
    _leaderboardController.add(_leaderboard);

    _friends = [
      ..._friends,
      Friend(
        userId: _currentUserId,
        friendId: targetUserId,
        username: targetUserId,
        displayName: targetUserId,
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
    _friendsController.add(_friends);
  }

  @override
  Future<List<FriendRequest>> getFriendRequests() async => _pendingRequests;

  @override
  Future<void> acceptFriendRequest(String fromUserId) async {
    final req = _pendingRequests
        .where((r) => r.fromUserId == fromUserId)
        .firstOrNull;
    _pendingRequests = _pendingRequests
        .where((r) => r.fromUserId != fromUserId)
        .toList();
    if (req == null) return;

    _friends = [
      ..._friends,
      Friend(
        userId: _currentUserId,
        friendId: req.fromUserId,
        username: req.fromUsername,
        displayName: req.fromDisplayName,
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
    _friendsController.add(_friends);

    final newEntry = LeaderboardEntry(
      userId: req.fromUserId,
      username: req.fromUsername,
      totalPoints: Random().nextInt(3000) + 500,
      rank: 0,
    );
    _leaderboard = _rerank([..._leaderboard, newEntry]);
    _leaderboardController.add(_leaderboard);
  }

  @override
  Future<void> declineFriendRequest(String fromUserId) async {
    _pendingRequests = _pendingRequests
        .where((r) => r.fromUserId != fromUserId)
        .toList();
  }

  @override
  Future<List<LeaderboardEntry>> fetchHistoricalLeaderboard(
    String date,
  ) async => [];

  @override
  Future<void> removeFriend(String targetUserId) async {
    _leaderboard = _leaderboard.where((e) => e.userId != targetUserId).toList();
    _leaderboardController.add(_leaderboard);

    _friends = _friends.where((f) => f.friendId != targetUserId).toList();
    _friendsController.add(_friends);
  }

  void dispose() {
    _tickTimer.cancel();
    _leaderboardController.close();
    _inventoryController.close();
    _stepController.close();
    _friendsController.close();
  }

  static List<LeaderboardEntry> _initialLeaderboard() => _rerank([
    LeaderboardEntry(
      userId: _currentUserId,
      username: 'you',
      totalPoints: 1840,
      rank: 0,
    ),
    LeaderboardEntry(
      userId: 'user-002',
      username: 'alex_walks',
      totalPoints: 3120,
      rank: 0,
    ),
    LeaderboardEntry(
      userId: 'user-003',
      username: 'steph_steps',
      totalPoints: 2750,
      rank: 0,
    ),
    LeaderboardEntry(
      userId: 'user-004',
      username: 'mike_miles',
      totalPoints: 980,
      rank: 0,
    ),
  ]);

  static List<InventoryItem> _initialInventory() => [
    InventoryItem(
      itemId: 'item-001',
      name: 'Double Points',
      description: 'Doubles your points for the next 30 minutes.',
      type: ItemType.powerup,
      expiresAt: neverExpires,
    ),
    InventoryItem(
      itemId: 'item-002',
      name: 'Step Drain',
      description: "Removes 7 points from a friend's total.",
      type: ItemType.attack,
      expiresAt: neverExpires,
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

  @override
  Stream<List<Friend>> watchFriends() async* {
    yield _friends;
    yield* _friendsController.stream;
  }

  static List<FriendRequest> _initialFriendRequests() => [
    FriendRequest(
      fromUserId: 'user-005',
      fromUsername: 'bob_runs',
      fromDisplayName: 'Bob',
      fromAvatarUrl: null,
      createdAt: '2026-05-27T10:00:00Z',
    ),
  ];

  static List<Friend> _initialFriends() => [
    Friend(
      userId: 'user-000',
      friendId: 'alice123',
      username: 'alice123',
      displayName: 'Alice',
      createdAt: '2026-05-18T12:00:00Z',
    ),
    Friend(
      userId: 'user-002',
      friendId: 'alex_walks',
      username: 'alex_walks',
      displayName: 'Alex',
      createdAt: '2026-05-18T12:00:00Z',
    ),
    Friend(
      userId: 'user-003',
      friendId: 'steph_steps',
      username: 'steph_steps',
      displayName: 'Steph',
      createdAt: '2026-05-18T12:00:00Z',
    ),
  ];

  @override
  Future<AvatarUploadResponse> getAvatarUploadUrl(String contentType) async {
    return AvatarUploadResponse(
      uploadUrl: 'mock-upload-url',
      publicUrl: 'https://i.imgur.com/oBPXx0D.png',
      contentType: contentType,
    );
  }

  @override
  Future<void> updateAvatarUrl(String avatarUrl) async {
    _avatarUrl = avatarUrl;
  }
}
