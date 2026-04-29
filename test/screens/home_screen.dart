import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/repository/mock_app_repository.dart';
import 'package:trak/screens/home_screen.dart';

void main() {
  testWidgets('home screen renders with mock repository', (tester) async {
    final repo = MockAppRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Trak'), findsOneWidget);
    expect(find.text('Steps today'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.byIcon(Icons.person_add), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);

    repo.dispose();
  });
}
