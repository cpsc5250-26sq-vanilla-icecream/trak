import 'package:flutter_test/flutter_test.dart';
import 'package:trak/models/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry.fromMap', () {
    test('maps snake_case DB columns', () {
      final map = {
        'user_id': 'u1',
        'username': 'alice',
        'avatar_url': 'https://example.com/pic.jpg',
        'points': 500,
        'rank': 1,
        'cached_at': 0,
      };

      final entry = LeaderboardEntry.fromMap(map);

      expect(entry.userId, 'u1');
      expect(entry.username, 'alice');
      expect(entry.avatarUrl, 'https://example.com/pic.jpg');
      expect(entry.totalPoints, 500);
      expect(entry.rank, 1);
    });

    test('allows null avatarUrl', () {
      final map = {
        'user_id': 'u2',
        'username': 'bob',
        'avatar_url': null,
        'points': 100,
        'rank': 2,
        'cached_at': 0,
      };

      final entry = LeaderboardEntry.fromMap(map);

      expect(entry.avatarUrl, isNull);
    });
  });

  group('LeaderboardEntry.fromCloud', () {
    test('maps camelCase API response', () {
      final map = {
        'userId': 'u1',
        'username': 'alice',
        'avatarUrl': 'https://example.com/pic.jpg',
        'points': 500,
        'rank': 1,
      };

      final entry = LeaderboardEntry.fromCloud(map);

      expect(entry.userId, 'u1');
      expect(entry.username, 'alice');
      expect(entry.avatarUrl, 'https://example.com/pic.jpg');
      expect(entry.totalPoints, 500);
      expect(entry.rank, 1);
    });

    test('allows null avatarUrl from cloud', () {
      final map = {
        'userId': 'u3',
        'username': 'carol',
        'avatarUrl': null,
        'points': 200,
        'rank': 3,
      };

      final entry = LeaderboardEntry.fromCloud(map);
      expect(entry.avatarUrl, isNull);
    });
  });

  group('LeaderboardEntry.toMap', () {
    test('serializes to snake_case for DB', () {
      const entry = LeaderboardEntry(
        userId: 'u1',
        username: 'alice',
        avatarUrl: 'https://example.com/pic.jpg',
        totalPoints: 500,
        rank: 1,
      );

      final map = entry.toMap();

      expect(map['user_id'], 'u1');
      expect(map['username'], 'alice');
      expect(map['avatar_url'], 'https://example.com/pic.jpg');
      expect(map['points'], 500);
      expect(map['rank'], 1);
      expect(map['cached_at'], isA<int>());
    });

    test('fromCloud → toMap round-trip preserves fields', () {
      final cloud = {
        'userId': 'u1',
        'username': 'alice',
        'avatarUrl': null,
        'points': 300,
        'rank': 2,
      };

      final map = LeaderboardEntry.fromCloud(cloud).toMap();

      expect(map['user_id'], 'u1');
      expect(map['points'], 300);
      expect(map['rank'], 2);
    });
  });
}
