import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/main.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/repository/mock_app_repository.dart';

void main() {
  testWidgets('app renders with mock repository', (tester) async {
    final repo = MockAppRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const TrakApp(),
      ),
    );

    // Allow streams to emit their first values.
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Trak'), findsOneWidget);
    expect(find.text('Steps today'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);

    // Must cancel the periodic timer before the test ends or the framework
    // will flag a pending timer as an error.
    repo.dispose();
  });
}
