import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Shows a live countdown to the next leaderboard reset/snapshot,
/// converted from the backend's UTC reset time to the device's local time.
class LeaderboardResetTimer extends ConsumerStatefulWidget {
  const LeaderboardResetTimer({super.key});

  @override
  ConsumerState<LeaderboardResetTimer> createState() =>
      _LeaderboardResetTimerState();
}

class _LeaderboardResetTimerState extends ConsumerState<LeaderboardResetTimer> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  static String _formatCountdown(Duration remaining) {
    if (remaining.isNegative) return 'Resetting…';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    if (hours > 0) return 'Resets in ${hours}h ${minutes}m';
    if (minutes > 0) return 'Resets in ${minutes}m ${seconds}s';
    return 'Resets in ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final resetTimeUtc = ref.watch(resetTimeProvider).asData?.value;
    if (resetTimeUtc == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final localResetTime = resetTimeUtc.toLocal();
    final remaining = localResetTime.difference(DateTime.now());
    final resetClock = TimeOfDay.fromDateTime(localResetTime).format(context);

    return Tooltip(
      message: 'Snapshots are taken daily at $resetClock your time',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(_formatCountdown(remaining), style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
