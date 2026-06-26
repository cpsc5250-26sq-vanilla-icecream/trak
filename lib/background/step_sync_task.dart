import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:health/health.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import '../auth/amplify_config.dart';
import '../database/app_database.dart';

const _taskName = 'trak.stepSync';
const _stepsUrl =
    'https://v1mm0rec3f.execute-api.us-east-1.amazonaws.com/prod/steps';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((_, _) async {
    try {
      await _pushSteps();
    } catch (e) {
      safePrint('Background step sync error: $e');
    }
    return true;
  });
}

Future<void> _pushSteps() async {
  if (!Amplify.isConfigured) {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyConfig);
  }

  final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
  if (!session.isSignedIn) return;
  final token = session.userPoolTokensResult.value.idToken.raw;

  final now = DateTime.now();
  final resetMs = await AppDatabase.instance.getResetTimeUtc(
    AppDatabase.defaultLeaderboardId,
  );
  final start = resetMs != null
      ? DateTime.fromMillisecondsSinceEpoch(resetMs, isUtc: true).toLocal()
      : DateTime(now.year, now.month, now.day);

  final health = Health();
  await health.requestAuthorization([HealthDataType.STEPS]);
  final steps = await health.getTotalStepsInInterval(start, now) ?? 0;

  await http.post(
    Uri.parse(_stepsUrl),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'stepCount': steps}),
  );
}

Future<void> initStepSyncTask() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _taskName,
    _taskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
