import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/login_screen.dart';
import '../screens/add_friend_screen.dart';
import '../screens/home_screen.dart';
import '../screens/placeholder_screens.dart';
import '../screens/shell_screen.dart';
import '../screens/username_screen.dart';
import 'router_notifier.dart';

abstract final class AppRoute {
  static const login = '/login';
  static const username = '/username';
  static const home = '/home';
  static const powerups = '/powerups';
  static const profile = '/profile';
  static const addFriend = '/friends/add';
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  return GoRouter(
    initialLocation: AppRoute.home,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: AppRoute.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoute.username,
        builder: (_, _) => const UsernameScreen(),
      ),
      GoRoute(
        path: AppRoute.addFriend,
        builder: (_, _) => const AddFriendScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.powerups,
                builder: (_, _) => const PowerupsPlaceholder(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile,
                builder: (_, _) => const ProfilePlaceholder(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

String? computeRedirect({
  required AsyncValue<AuthUser?> authState,
  required AsyncValue<bool> needsUsername,
  required String currentLocation,
}) {
  if (authState.isLoading) {
    return null;
  }
  final isSignedIn = authState.asData?.value != null;
  if (!isSignedIn) {
    return currentLocation == AppRoute.login ? null : AppRoute.login;
  }
  if (needsUsername.isLoading) {
    return null;
  }
  final needsName = needsUsername.asData?.value ?? false;
  if (needsName) {
    return currentLocation == AppRoute.username ? null : AppRoute.username;
  }
  if (currentLocation == AppRoute.login ||
      currentLocation == AppRoute.username) {
    return AppRoute.home;
  }
  return null;
}
