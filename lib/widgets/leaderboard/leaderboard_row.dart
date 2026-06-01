import 'package:flutter/material.dart';
import '../../models/leaderboard_entry.dart';
import 'rank_avatar.dart';

class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  const LeaderboardRow({
    super.key,
    required this.entry,
    required this.isCurrentUser,
  });

  Color _rankColor(int rank) => switch (rank) {
    1 => const Color(0xFFFFD700),
    2 => const Color(0xFFB0BEC5),
    3 => const Color(0xFFCD7F32),
    _ => const Color(0xFFE0E0E0),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        leading: RankAvatar(rank: entry.rank, color: _rankColor(entry.rank)),
        title: _LeaderboardName(
          name: entry.displayName ?? entry.username,
          isCurrentUser: isCurrentUser,
        ),
        trailing: _PointsDisplay(points: entry.totalPoints),
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
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
