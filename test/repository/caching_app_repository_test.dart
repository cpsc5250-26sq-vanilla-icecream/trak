import 'package:flutter_test/flutter_test.dart';
import 'package:trak/models/friend.dart';
import 'package:trak/models/friend_request.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/repository/caching_app_repository.dart';
import 'package:trak/repository/cloud_repository.dart';
import 'package:trak/repository/sqf_repository.dart';

class _FakeCloud extends CloudRepository {
  String? addedFriendUsername;
  bool addFriendShouldThrow = false;
  String? removedFriendId;
  String? acceptedFromUserId;
  final List<LeaderboardEntry> leaderboard;

  _FakeCloud({this.leaderboard = const []});

  @override
  Future<void> addFriend(String username) async {
    if (addFriendShouldThrow) throw Exception('User not found');
    addedFriendUsername = username;
  }

  @override
  Future<void> removeFriend(String friendId) async {
    removedFriendId = friendId;
  }

  @override
  Future<void> acceptFriendRequest(String fromUserId) async {
    acceptedFromUserId = fromUserId;
  }

  @override
  Future<void> declineFriendRequest(String fromUserId) async {}

  @override
  Future<List<FriendRequest>> fetchFriendRequests() async => [];

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard({String? date}) async =>
      leaderboard;

  @override
  Future<({List<LeaderboardEntry> entries, int resetTimeUtc})>
  fetchTodayLeaderboard() async => (entries: leaderboard, resetTimeUtc: 0);

  @override
  Future<List<Friend>> fetchFriends() async => [];
}

class _FakeCache extends SqfRepository {
  List<LeaderboardEntry>? pushedLeaderboard;
  List<Friend>? pushedFriends;

  @override
  Future<void> pushLeaderboard(
    List<LeaderboardEntry> entries, {
    required int resetTimeUtc,
    String leaderboardId = 'default',
  }) async {
    pushedLeaderboard = entries;
  }

  @override
  Future<void> pushFriends(List<Friend> friends) async {
    pushedFriends = friends;
  }
}

const _entry = LeaderboardEntry(
  userId: 'u1',
  username: 'alice',
  totalPoints: 500,
  rank: 1,
);

void main() {
  group('CachingAppRepository.addFriend', () {
    late _FakeCloud cloud;
    late _FakeCache cache;
    late CachingAppRepository repo;

    setUp(() {
      cloud = _FakeCloud(leaderboard: [_entry]);
      cache = _FakeCache();
      repo = CachingAppRepository(cloud: cloud, cache: cache);
    });

    test('calls cloud addFriend with correct username', () async {
      await repo.addFriend('bob');
      expect(cloud.addedFriendUsername, 'bob');
    });

    test('pushes refreshed leaderboard to cache after add', () async {
      await repo.addFriend('bob');
      expect(cache.pushedLeaderboard, [_entry]);
    });

    test('does not push to cache if cloud addFriend throws', () async {
      cloud.addFriendShouldThrow = true;
      await expectLater(repo.addFriend('ghost'), throwsException);
      expect(cache.pushedLeaderboard, isNull);
    });
  });

  group('CachingAppRepository.removeFriend', () {
    late _FakeCloud cloud;
    late _FakeCache cache;
    late CachingAppRepository repo;

    setUp(() {
      cloud = _FakeCloud(leaderboard: [_entry]);
      cache = _FakeCache();
      repo = CachingAppRepository(cloud: cloud, cache: cache);
    });

    test('calls cloud removeFriend with correct friendId', () async {
      await repo.removeFriend('u1');
      expect(cloud.removedFriendId, 'u1');
    });

    test('pushes refreshed leaderboard to cache after remove', () async {
      await repo.removeFriend('u1');
      expect(cache.pushedLeaderboard, [_entry]);
    });
  });

  group('CachingAppRepository.acceptFriendRequest', () {
    late _FakeCloud cloud;
    late _FakeCache cache;
    late CachingAppRepository repo;

    setUp(() {
      cloud = _FakeCloud(leaderboard: [_entry]);
      cache = _FakeCache();
      repo = CachingAppRepository(cloud: cloud, cache: cache);
    });

    test('calls cloud acceptFriendRequest with correct userId', () async {
      await repo.acceptFriendRequest('u1');
      expect(cloud.acceptedFromUserId, 'u1');
    });

    test('pushes refreshed leaderboard to cache after accept', () async {
      await repo.acceptFriendRequest('u1');
      expect(cache.pushedLeaderboard, [_entry]);
    });
  });
}
