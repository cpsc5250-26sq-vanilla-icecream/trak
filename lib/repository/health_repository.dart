import 'package:health/health.dart';
import '../database/app_database.dart';

class HealthRepository {
  final Health _health = Health();

  Future<void> requestPermission() async {
    await _health.requestAuthorization([HealthDataType.STEPS]);
  }

  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final resetMs = await AppDatabase.instance.getResetTimeUtc(
      AppDatabase.defaultLeaderboardId,
    );
    final today = DateTime(now.year, now.month, now.day);
    final cachedReset = resetMs != null
        ? DateTime.fromMillisecondsSinceEpoch(resetMs, isUtc: true).toLocal()
        : null;
    final start = (cachedReset != null && cachedReset.isAfter(today))
        ? cachedReset
        : today;

    final steps = await _health.getTotalStepsInInterval(start, now);

    return steps ?? 0;
  }
}
