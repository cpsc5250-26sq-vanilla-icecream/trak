import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/repository/cloud_repository.dart';
import 'package:trak/service/push_notification_service.dart';
import 'auth/amplify_config.dart';
import 'background/step_sync_task.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  await Firebase.initializeApp();
  await PushNotificationService.initialize();
  await initStepSyncTask();
  runApp(const ProviderScope(child: TrakApp()));
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyConfig);
  } on Exception catch (e) {
    debugPrint('Failed to configure Amplify: $e');
    rethrow;
  }
}

class TrakApp extends ConsumerWidget {
  const TrakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Trak',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      routerConfig: router,
    );
  }
}
