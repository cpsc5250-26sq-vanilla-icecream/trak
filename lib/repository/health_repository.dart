import 'package:health/health.dart';

class HealthRepository {
  final Health _health = Health();

  // Get permission from Health Connect
  // This must be called before getting data!
  Future<void> requestPermission() async {
    await _health.requestAuthorization([HealthDataType.STEPS]);
  }

  // Get the step count from Health Connect
  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    final steps = await _health.getTotalStepsInInterval(start, now);

    return steps ?? 0;
  }
}
