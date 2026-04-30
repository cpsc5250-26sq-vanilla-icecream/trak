import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../providers/app_providers.dart';
import 'add_friend_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
            icon: const Icon(Icons.person_add),
            tooltip: 'Add friend',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddFriendScreen()),
            ),
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
    );
  }
}
