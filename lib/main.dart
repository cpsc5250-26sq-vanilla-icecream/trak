import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_providers.dart';
import 'repository/mock_app_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(MockAppRepository())],
      child: const TrakApp(),
    ),
  );
}

class TrakApp extends StatelessWidget {
  const TrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trak',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const HomeScreen(),
    );
  }
}
