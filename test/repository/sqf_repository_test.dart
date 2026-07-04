import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trak/database/app_database.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/repository/sqf_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;
  late SqfRepository repo;

  setUp(() async {
    appDb = await AppDatabase.openInMemory();
    repo = SqfRepository(db: appDb);
  });

  tearDown(() async {
    repo.dispose();
    await appDb.close();
  });

  group('SqfRepository.putSteps / watchStepCount', () {
    test('watchStepCount emits 0 when no steps stored', () async {
      expect(await repo.watchStepCount().first, 0);
    });

    test('putSteps persists steps and stream emits new value', () async {
      await repo.putSteps(1234);
      expect(await repo.watchStepCount().first, 1234);
    });

    test('putSteps overwrites previous value for the same day', () async {
      await repo.putSteps(500);
      await repo.putSteps(900);
      expect(await repo.watchStepCount().first, 900);
    });
  });

  group('SqfRepository.pushLeaderboard / watchLeaderboard', () {
    const alice = LeaderboardEntry(
      userId: 'u1',
      username: 'alice',
      totalPoints: 800,
      rank: 1,
    );
    const bob = LeaderboardEntry(
      userId: 'u2',
      username: 'bob',
      totalPoints: 400,
      rank: 2,
    );

    test('watchLeaderboard emits empty list when nothing stored', () async {
      expect(await repo.watchLeaderboard().first, isEmpty);
    });

    test('pushLeaderboard persists entries and stream emits them', () async {
      await repo.pushLeaderboard([alice, bob], resetTimeUtc: 1_700_000_000_000);
      final entries = await repo.watchLeaderboard().first;
      expect(entries.map((e) => e.userId), containsAll(['u1', 'u2']));
    });

    test('pushLeaderboard replaces previous entries', () async {
      await repo.pushLeaderboard([alice, bob], resetTimeUtc: 1_700_000_000_000);
      const carol = LeaderboardEntry(
        userId: 'u3',
        username: 'carol',
        totalPoints: 1200,
        rank: 1,
      );
      await repo.pushLeaderboard([carol], resetTimeUtc: 1_700_000_000_000);
      final entries = await repo.watchLeaderboard().first;
      expect(entries, hasLength(1));
      expect(entries.first.userId, 'u3');
    });

    test('entries are returned ordered by rank', () async {
      await repo.pushLeaderboard([bob, alice], resetTimeUtc: 1_700_000_000_000);
      final entries = await repo.watchLeaderboard().first;
      expect(entries.first.rank, 1);
      expect(entries.last.rank, 2);
    });

    test('pushLeaderboard persists resetTimeUtc to leaderboard_meta', () async {
      await repo.pushLeaderboard([alice], resetTimeUtc: 1_700_000_000_000);
      final saved = await appDb.getResetTimeUtc(
        AppDatabase.defaultLeaderboardId,
      );
      expect(saved, 1_700_000_000_000);
    });
  });
}
