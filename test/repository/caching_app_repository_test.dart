import 'package:flutter_test/flutter_test.dart';
import 'package:trak/models/friend.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/repository/caching_app_repository.dart';
import 'package:trak/repository/cloud_repository.dart';
import 'package:trak/repository/sqf_repository.dart';

class _FakeCloud extends CloudRepository {
  String? addedFriendUsername;
  bool addFriendShouldThrow = false;
  final List<LeaderboardEntry> leaderboard;

  _FakeCloud({this.leaderboard = const []});

  @override
  Future<void> addFriend(String username) async {
    if (addFriendShouldThrow) throw Exception('User not found');
    addedFriendUsername = username;
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard() async => leaderboard;

  @override
  Future<List<Friend>> fetchFriends() async => [];
}

class _FakeCache extends SqfRepository {
  List<LeaderboardEntry>? pushedLeaderboard;
  List<Friend>? pushedFriends;

  @override
  Future<void> pushLeaderboard(List<LeaderboardEntry> entries) async {
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
}
