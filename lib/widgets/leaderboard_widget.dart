import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_entry.dart';
import '../providers/app_providers.dart';

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
              (entry) => _LeaderboardRow(
                entry: entry,
                isCurrentUser: entry.userId == currentUserId,
              ),
            )
            .toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({required this.entry, required this.isCurrentUser});

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFB0BEC5);
  static const _bronze = Color(0xFFCD7F32);

  Color _rankColor(int rank) => switch (rank) {
    1 => _gold,
    2 => _silver,
    3 => _bronze,
    _ => const Color(0xFFE0E0E0),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankColor = _rankColor(entry.rank);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _RankAvatar(rank: entry.rank, color: rankColor),
        title: _LeaderboardName(
          name: entry.displayName ?? entry.username,
          isCurrentUser: isCurrentUser,
        ),
        trailing: _PointsDisplay(points: entry.totalPoints),
      ),
    );
  }
}

class _RankAvatar extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankAvatar({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;

    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isTopThree ? Colors.black87 : Colors.black54,
        ),
      ),
    );
  }
}

class _LeaderboardName extends StatelessWidget {
  final String name;
  final bool isCurrentUser;

  const _LeaderboardName({required this.name, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        if (isCurrentUser) ...[const SizedBox(width: 6), const _YouBadge()],
      ],
    );
  }
}

class _YouBadge extends StatelessWidget {
  const _YouBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'you',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PointsDisplay extends StatelessWidget {
  final int points;

  const _PointsDisplay({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$points',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'pts',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
