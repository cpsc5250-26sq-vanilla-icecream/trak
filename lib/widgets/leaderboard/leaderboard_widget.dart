import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import 'leaderboard_row.dart';

class LeaderboardWidget extends ConsumerWidget {
  const LeaderboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider).asData?.value.userId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Leaderboard', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _LeaderboardContent(currentUserId: currentUserId),
      ],
    );
  }
}

class _LeaderboardContent extends ConsumerWidget {
  final String? currentUserId;
  const _LeaderboardContent({required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    return leaderboard.when(
      data: (entries) => Column(
        children: entries
            .map(
              (e) => LeaderboardRow(
                entry: e,
                isCurrentUser: e.userId == currentUserId,
              ),
            )
            .toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
