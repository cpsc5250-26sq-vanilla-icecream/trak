import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class MockToggle extends ConsumerWidget {
  const MockToggle({super.key});

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
          onChanged: (v) {
            ref.read(useMockProvider.notifier).set(v);
          },
        ),
      ],
    );
  }
}
