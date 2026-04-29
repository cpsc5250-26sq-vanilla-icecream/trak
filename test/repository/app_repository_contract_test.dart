import 'package:flutter_test/flutter_test.dart';
import 'package:trak/repository/app_repository.dart';
import 'package:trak/repository/mock_app_repository.dart';

void main() {
  group('AppRepository.addFriend contract', () {
    late AppRepository repo;

    setUp(() => repo = MockAppRepository());
    tearDown(() => (repo as MockAppRepository).dispose());

    test('adds entry with given username', () async {
      await repo.addFriend('new_pal');
      final leaderboard = await repo.watchLeaderboard().first;
      expect(leaderboard.any((e) => e.username == 'new_pal'), isTrue);
    });

    test('new entry has matching userId', () async {
      await repo.addFriend('new_pal');
      final leaderboard = await repo.watchLeaderboard().first;
      final entry = leaderboard.firstWhere((e) => e.username == 'new_pal');
      expect(entry.userId, 'new_pal');
    });

    test('leaderboard grows by one', () async {
      final before = (await repo.watchLeaderboard().first).length;
      await repo.addFriend('new_pal');
      final after = (await repo.watchLeaderboard().first).length;
      expect(after, before + 1);
    });

    test('leaderboard ranks are contiguous after add', () async {
      await repo.addFriend('new_pal');
      final leaderboard = await repo.watchLeaderboard().first;
      final ranks = leaderboard.map((e) => e.rank).toList()..sort();
      expect(ranks, List.generate(leaderboard.length, (i) => i + 1));
    });

    test('emits updated leaderboard on stream', () async {
      final future = repo.watchLeaderboard().skip(1).first;
      await repo.addFriend('streamed_pal');
      final leaderboard = await future;
      expect(leaderboard.any((e) => e.username == 'streamed_pal'), isTrue);
    });
  });
}
