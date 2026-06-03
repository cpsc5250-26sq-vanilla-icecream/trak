import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../utils/points_utils.dart';
import '../widgets/leaderboard_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add friend',
            onPressed: () => context.push(AppRoute.addFriend),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncServiceProvider).syncOnForeground(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _UserHeader(),
                const SizedBox(height: 24),
                const _StepsSection(),
                const SizedBox(height: 32),
                LeaderboardWidget(
                  onHistoryTap: () =>
                      context.push(AppRoute.historicalLeaderboard),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserHeader extends ConsumerWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return user.when(
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
    );
  }
}

class _StepsSection extends ConsumerWidget {
  const _StepsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepCountProvider);
    final confirmedPoints = ref.watch(currentUserPointsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Steps today', style: Theme.of(context).textTheme.labelLarge),
        steps.when(
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$s', style: Theme.of(context).textTheme.displayMedium),
              Text(
                '≈ ${stepsToPoints(s)} pts today · '
                '$confirmedPoints pts total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}
