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
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyConfig);
  } on Exception catch (e) {
    debugPrint('Failed to configure Amplify: $e');
    rethrow;
  }
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
    ref.listen(authStateProvider, (_, next) {
      if (!next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    });

    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const LoginScreen(),
      data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}

// Temporary home screen — replace with real screens as they're built.
class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepCountProvider);
    final leaderboard = ref.watch(leaderboardProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            user.when(
              data: (u) => Text(
                'Hello, ${u.displayName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            Text('Steps today', style: Theme.of(context).textTheme.labelLarge),
            steps.when(
              data: (s) =>
                  Text('$s', style: Theme.of(context).textTheme.displayMedium),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),
            Text('Leaderboard', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            leaderboard.when(
              data: (entries) => Column(
                children: entries
                    .map(
                      (e) => ListTile(
                        leading: Text('#${e.rank}'),
                        title: Text(e.username),
                        trailing: Text('${e.totalPoints} pts'),
                      ),
                    )
                    .toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
