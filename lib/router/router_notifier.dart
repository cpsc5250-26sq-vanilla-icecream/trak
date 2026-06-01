import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../providers/app_providers.dart';
import 'app_router.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _hasSynced = false;

  RouterNotifier(this._ref) {
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
