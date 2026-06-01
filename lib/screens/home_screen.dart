import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../widgets/leaderboard/leaderboard_widget.dart';
import '../widgets/mock_toggle.dart';
import '../widgets/steps_section.dart';
import '../widgets/test_notification_button.dart';
import '../widgets/user_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trak'),
        actions: [
          if (kDebugMode) const MockToggle(),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add friend',
            onPressed: () => context.push(AppRoute.addFriend),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(authStateProvider.notifier).signOut(),
        child: const Icon(Icons.logout),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncServiceProvider).syncOnForeground(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                UserHeader(),
                SizedBox(height: 24),
                StepsSection(),
                SizedBox(height: 32),
                LeaderboardWidget(),
                SizedBox(height: 32),
                TestNotificationButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
