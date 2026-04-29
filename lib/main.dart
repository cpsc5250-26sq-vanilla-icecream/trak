import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/amplify_config.dart';
import 'auth/auth_notifier.dart';
import 'auth/login_screen.dart';
import 'providers/app_providers.dart';
import 'repository/mock_app_repository.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(MockAppRepository())],
      child: const TrakApp(),
    ),
  );
}

Future<void> _configureAmplify() async {
  await Amplify.addPlugin(AmplifyAuthCognito());
  await Amplify.configure(amplifyConfig);
}

class TrakApp extends StatelessWidget {
  const TrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trak',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const LoginScreen(),
      data: (user) => user != null ? const _HomePage() : const LoginScreen(),
    );
  }
}
