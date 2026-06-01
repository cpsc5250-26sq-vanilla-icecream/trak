import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../utils/points_utils.dart';

class StepsSection extends ConsumerWidget {
  const StepsSection({super.key});

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
