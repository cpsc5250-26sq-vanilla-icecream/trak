import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trak/screens/powerup_screen.dart';
import 'package:trak/screens/user_profile_screen.dart';
import '../auth/auth_notifier.dart';
import '../auth/login_screen.dart';
import '../providers/app_providers.dart';
import '../screens/add_friend_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/username_screen.dart';

abstract final class AppRoute {
  static const login = '/login';
  static const username = '/username';
  static const home = '/home';
  static const powerups = '/powerups';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const addFriend = '/friends/add';
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
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
                builder: (_, _) => const PowerupScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile,
                builder: (_, _) => const UserProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, _) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Pure redirect logic — no Riverpod or GoRouter dependencies, testable in isolation.
String? computeRedirect({
  required AsyncValue<AuthUser?> authState,
  required AsyncValue<bool> needsUsername,
  required String currentLocation,
}) {
  if (authState.isLoading) return null;

  final isSignedIn = authState.asData?.value != null;
  if (!isSignedIn) {
    return currentLocation == AppRoute.login ? null : AppRoute.login;
  }

  if (needsUsername.isLoading) return null;

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

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _hasSynced = false;

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (prev, next) {
      _onAuthChanged(prev, next);
      notifyListeners();
    });
    _ref.listen(needsUsernameProvider, (prev, next) {
      _onUsernameChanged(prev, next);
      notifyListeners();
    });
  }

  void _onAuthChanged(AsyncValue<AuthUser?>? prev, AsyncValue<AuthUser?> next) {
    if (next.isLoading) return;
    final isSignedIn = next.asData?.value != null;
    if (!isSignedIn) {
      _hasSynced = false;
      return;
    }
    final sync = _ref.read(syncServiceProvider);
    if (!_hasSynced) {
      _hasSynced = true;
      sync.syncOnLogin();
    } else {
      sync.syncOnForeground();
    }
  }

  void _onUsernameChanged(AsyncValue<bool>? prev, AsyncValue<bool> next) {
    final justSetUsername =
        prev?.asData?.value == true && next.asData?.value == false;
    if (!justSetUsername) return;
    _ref.invalidate(currentUserProvider);
    _ref.read(syncServiceProvider).syncOnForeground();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    return computeRedirect(
      authState: _ref.read(authStateProvider),
      needsUsername: _ref.read(needsUsernameProvider),
      currentLocation: state.matchedLocation,
    );
  }
}
