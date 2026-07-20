import 'package:flutter_test/flutter_test.dart';
import 'package:trak/utils/points_utils.dart';

void main() {
  group('stepsToPoints', () {
    test('returns 0 for fewer than 100 steps', () {
      expect(stepsToPoints(0), 0);
      expect(stepsToPoints(99), 0);
    });

    test('returns 1 for exactly 100 steps', () {
      expect(stepsToPoints(100), 1);
    });

    test('truncates fractional points', () {
      expect(stepsToPoints(150), 1);
      expect(stepsToPoints(199), 1);
    });

    test('scales correctly for large counts', () {
      expect(stepsToPoints(10000), 100);
    });
  });

  group('resolveStepWindowStart', () {
    final now = DateTime(2026, 7, 9, 14, 0, 0); // 2pm local on July 9
    final todayMidnight = DateTime(2026, 7, 9);

    test('returns today midnight when resetMs is null', () {
      expect(resolveStepWindowStart(now, null), todayMidnight);
    });

    test('returns cached reset time when it falls within today', () {
      // 6am today local — still within today
      final todayReset = DateTime(2026, 7, 9, 6, 0, 0);
      final resetMs = todayReset.toUtc().millisecondsSinceEpoch;
      expect(resolveStepWindowStart(now, resetMs), todayReset);
    });

    test('returns today midnight when cached reset is from yesterday', () {
      // midnight yesterday local — stale after the day rolled over
      final yesterdayReset = DateTime(2026, 7, 8, 0, 0, 0);
      final resetMs = yesterdayReset.toUtc().millisecondsSinceEpoch;
      expect(resolveStepWindowStart(now, resetMs), todayMidnight);
    });

    test(
      'returns today midnight when cached reset equals today midnight exactly',
      () {
        // Exactly midnight is not after today, so should fall back
        final resetMs = todayMidnight.toUtc().millisecondsSinceEpoch;
        expect(resolveStepWindowStart(now, resetMs), todayMidnight);
      },
    );
  });
}
