import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trak/service/local_notification_service.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../widgets/leaderboard_widget.dart';
import '../utils/points_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepCountProvider);
    final user = ref.watch(currentUserProvider);
    final confirmedPoints = ref.watch(currentUserPointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trak'),
        actions: [
          if (kDebugMode) _MockToggle(),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add friend',
            onPressed: () => context.push(AppRoute.addFriend),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(authStateProvider.notifier).signOut(),
        child: const Icon(Icons.logout),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            user.when(
              data: (u) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${u.displayName.isNotEmpty ? u.displayName : u.username}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '@${u.username}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            Text('Steps today', style: Theme.of(context).textTheme.labelLarge),
            steps.when(
              data: (s) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$s', style: Theme.of(context).textTheme.displayMedium),
                  Text(
                    '≈ ${stepsToPoints(s)} pts today  ·  $confirmedPoints pts total',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),
            const LeaderboardWidget(),
            const SizedBox(height: 32),
            const _TestNotification(),
          ],
        ),
      ),
    );
  }
}

class _MockToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMock = ref.watch(useMockProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          useMock ? 'Mock' : 'Live',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Switch(
          value: useMock,
          onChanged: (v) => ref.read(useMockProvider.notifier).set(v),
        ),
      ],
    );
  }
}

class _TestNotification extends StatelessWidget {
  const _TestNotification();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await LocalNotificationService.showNotification();
      },
      child: Text("Push Test Notification"),
    );
  }
}
