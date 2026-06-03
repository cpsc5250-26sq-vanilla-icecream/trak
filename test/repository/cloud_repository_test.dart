import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trak/repository/cloud_repository.dart';

String _makeToken(Map<String, dynamic> claims) {
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
  return 'eyJhbGciOiJSUzI1NiJ9.$payload.fakesig';
}

CloudRepository _repo(
  Future<http.Response> Function(http.Request) handler, {
  String? token,
}) {
  return CloudRepository(
    client: MockClient(handler),
    tokenGetter: () async => token ?? _makeToken({}),
  );
}

void main() {
  group('CloudRepository.getCurrentUser', () {
    test('returns UserProfile on 200', () async {
      final repo = _repo(
        (_) async => http.Response(
          jsonEncode({
            'userId': 'u1',
            'username': 'alice',
            'displayName': 'Alice Smith',
            'avatarUrl': 'https://example.com/avatar.jpg',
          }),
          200,
        ),
      );

      final profile = await repo.getCurrentUser();

      expect(profile.userId, 'u1');
      expect(profile.username, 'alice');
      expect(profile.displayName, 'Alice Smith');
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('handles null optional fields', () async {
      final repo = _repo(
        (_) async => http.Response(
          jsonEncode({'userId': 'u1', 'username': null, 'displayName': null}),
          200,
        ),
      );

      final profile = await repo.getCurrentUser();

      expect(profile.username, '');
      expect(profile.displayName, '');
      expect(profile.avatarUrl, isNull);
    });

    test('throws UserNotFoundException on 404', () async {
      final repo = _repo((_) async => http.Response('Not Found', 404));
      await expectLater(
        repo.getCurrentUser(),
        throwsA(isA<UserNotFoundException>()),
      );
    });

    test('throws Exception on non-2xx', () async {
      final repo = _repo((_) async => http.Response('Server error', 500));
      await expectLater(repo.getCurrentUser(), throwsException);
    });
  });

  group('CloudRepository.setUsername', () {
    test('completes on 200', () async {
      final repo = _repo((_) async => http.Response('', 200));
      await expectLater(repo.setUsername('alice'), completes);
    });

    test('throws UsernameAlreadyTakenException on 409', () async {
      final repo = _repo((_) async => http.Response('Conflict', 409));
      await expectLater(
        repo.setUsername('taken'),
        throwsA(isA<UsernameAlreadyTakenException>()),
      );
    });

    test('throws Exception on other non-2xx', () async {
      final repo = _repo((_) async => http.Response('', 500));
      await expectLater(repo.setUsername('alice'), throwsException);
    });
  });

  group('CloudRepository.fetchLeaderboard', () {
    test('deserializes entries correctly', () async {
      final repo = _repo(
        (_) async => http.Response(
          jsonEncode([
            {'userId': 'u1', 'username': 'alice', 'points': 800, 'rank': 1},
            {'userId': 'u2', 'username': 'bob', 'points': 400, 'rank': 2},
          ]),
          200,
        ),
      );

      final entries = await repo.fetchLeaderboard();

      expect(entries, hasLength(2));
      expect(entries[0].userId, 'u1');
      expect(entries[0].totalPoints, 800);
      expect(entries[1].rank, 2);
    });

    test('returns empty list for empty array', () async {
      final repo = _repo((_) async => http.Response('[]', 200));
      expect(await repo.fetchLeaderboard(), isEmpty);
    });

    test('throws on non-2xx', () async {
      final repo = _repo((_) async => http.Response('', 503));
      await expectLater(repo.fetchLeaderboard(), throwsException);
    });
  });

  group('CloudRepository.fetchFriends', () {
    test('deserializes friends correctly', () async {
      final repo = _repo(
        (_) async => http.Response(
          jsonEncode([
            {
              'userId': 'u1',
              'friendId': 'f1',
              'username': 'alice',
              'displayName': 'Alice',
              'createdAt': '2024-01-01',
            },
          ]),
          200,
        ),
      );

      final friends = await repo.fetchFriends();

      expect(friends, hasLength(1));
      expect(friends.first.friendId, 'f1');
      expect(friends.first.username, 'alice');
    });

    test('throws on non-2xx', () async {
      final repo = _repo((_) async => http.Response('', 500));
      await expectLater(repo.fetchFriends(), throwsException);
    });
  });

  group('CloudRepository.addFriend', () {
    test('completes on 200', () async {
      final repo = _repo((_) async => http.Response('', 200));
      await expectLater(repo.addFriend('bob'), completes);
    });

    test('throws on non-2xx', () async {
      final repo = _repo((_) async => http.Response('Not Found', 404));
      await expectLater(repo.addFriend('ghost'), throwsException);
    });
  });

  group('CloudRepository.removeFriend', () {
    test('completes on 200', () async {
      final repo = _repo((_) async => http.Response('', 200));
      await expectLater(repo.removeFriend('f1'), completes);
    });

    test('throws on non-2xx', () async {
      final repo = _repo((_) async => http.Response('', 404));
      await expectLater(repo.removeFriend('f1'), throwsException);
    });
  });

  group('CloudRepository.submitSteps', () {
    test('completes on 200', () async {
      final repo = _repo((_) async => http.Response('', 200));
      await expectLater(repo.submitSteps(5000), completes);
    });

    test('sends correct step count in request body', () async {
      http.Request? captured;
      final repo = _repo((req) async {
        captured = req;
        return http.Response('', 200);
      });

      await repo.submitSteps(7500);

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['stepCount'], 7500);
    });

    test('throws on non-2xx', () async {
      final repo = _repo((_) async => http.Response('', 500));
      await expectLater(repo.submitSteps(0), throwsException);
    });
  });

  group('CloudRepository.upsertUser', () {
    test('includes name and picture from JWT claims in request body', () async {
      final token = _makeToken({
        'name': 'Alice Smith',
        'picture': 'https://example.com/pic.jpg',
      });
      http.Request? captured;
      final repo = _repo((req) async {
        captured = req;
        return http.Response('', 200);
      }, token: token);

      await repo.upsertUser();

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['displayName'], 'Alice Smith');
      expect(body['avatarUrl'], 'https://example.com/pic.jpg');
    });

    test('omits fields absent from JWT claims', () async {
      final token = _makeToken({'sub': 'user-123'});
      http.Request? captured;
      final repo = _repo((req) async {
        captured = req;
        return http.Response('', 200);
      }, token: token);

      await repo.upsertUser();

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body.containsKey('displayName'), isFalse);
      expect(body.containsKey('avatarUrl'), isFalse);
    });

    test('throws on non-2xx', () async {
      final repo = _repo((_) async => http.Response('', 500));
      await expectLater(repo.upsertUser(), throwsException);
    });
  });

  group('CloudRepository.fetchLeaderboard (historical)', () {
    test('returns empty list on 404 when date is provided', () async {
      final repo = _repo(
        (_) async => http.Response(
          jsonEncode({'message': 'No snapshot available for that date'}),
          404,
        ),
      );
      expect(await repo.fetchLeaderboard(date: '2025-01-01'), isEmpty);
    });

    test('returns entries on 200 when date is provided', () async {
      final repo = _repo(
        (_) async => http.Response(
          jsonEncode([
            {'userId': 'u1', 'username': 'alice', 'points': 800, 'rank': 1},
          ]),
          200,
        ),
      );
      final entries = await repo.fetchLeaderboard(date: '2025-01-01');
      expect(entries, hasLength(1));
      expect(entries.first.userId, 'u1');
    });

    test('sends date as query parameter', () async {
      Uri? captured;
      final repo = _repo((req) async {
        captured = req.url;
        return http.Response('[]', 200);
      });
      await repo.fetchLeaderboard(date: '2025-06-01');
      expect(captured?.queryParameters['date'], '2025-06-01');
    });

    test('throws on non-404 error when date is provided', () async {
      final repo = _repo((_) async => http.Response('', 500));
      await expectLater(
        repo.fetchLeaderboard(date: '2025-01-01'),
        throwsException,
      );
    });
  });

  group('CloudRepository.useItem', () {
    test('returns success result on 200', () async {
      final repo = _repo((_) async => http.Response('', 200));
      final result = await repo.useItem('item1', 'target1');
      expect(result.success, isTrue);
    });

    test('returns failure result with message on 404', () async {
      final repo = _repo(
        (_) async =>
            http.Response(jsonEncode({'message': 'Item not found'}), 404),
      );
      final result = await repo.useItem('item1', 'target1');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Item not found');
    });

    test('throws on other non-2xx', () async {
      final repo = _repo((_) async => http.Response('', 500));
      await expectLater(repo.useItem('item1', 'target1'), throwsException);
    });
  });
}
