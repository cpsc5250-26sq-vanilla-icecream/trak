import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/amplify_config.dart';
import 'auth/auth_notifier.dart';
import 'auth/login_screen.dart';
import 'providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'screens/username_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
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
    ref.listen(needsUsernameProvider, (prev, next) {
      final justSetUsername =
          prev?.asData?.value == true && next.asData?.value == false;
      if (justSetUsername) ref.read(syncServiceProvider).syncOnForeground();
    });

    ref.listen(authStateProvider, (prev, next) {
      final wasSignedIn = prev?.asData?.value != null;
      final isSignedIn = next.asData?.value != null;

      if (isSignedIn) {
        final sync = ref.read(syncServiceProvider);
        if (!wasSignedIn) {
          sync.syncOnLogin();
        } else {
          sync.syncOnForeground();
        }
      }

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
      data: (user) {
        if (user == null) return const LoginScreen();
        return ref
            .watch(needsUsernameProvider)
            .when(
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to load profile'),
                      TextButton(
                        onPressed: () => ref.invalidate(needsUsernameProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (needs) =>
                  needs ? const UsernameScreen() : const HomeScreen(),
            );
      },
    );
  }
}
