import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../service/push_notification_service.dart';

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final subscription = Amplify.Hub.listen(HubChannel.Auth, (event) async {
      if (event.type == AuthHubEventType.signedIn) {
        await _saveCurrentToken();
        await refresh();
      } else if (event.type == AuthHubEventType.signedOut) {
        state = const AsyncData(null);
      }
    });
    ref.onDispose(subscription.cancel);

    try {
      final user = await Amplify.Auth.getCurrentUser();
      // Already logged in from a previous session — save token now since
      // the signedIn Hub event won't fire for a restored session.
      await _saveCurrentToken();
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCurrentToken() async {
    try {
      // Re-initialize to wire up onTokenRefresh with a save callback, then
      // grab the current token.  initialize() is idempotent for the listener.
      final token = await PushNotificationService.initialize(
        onTokenRefresh: (newToken) async {
          try {
            await ref.read(cloudRepositoryProvider).saveFcmToken(newToken);
            debugPrint('FCM token refreshed and saved');
          } catch (e) {
            debugPrint('Failed to save refreshed FCM token: $e');
          }
        },
      );
      debugPrint('TOKEN: $token');
      if (token != null) {
        await ref.read(cloudRepositoryProvider).saveFcmToken(token);
        debugPrint('TOKEN SAVED TO BACKEND');
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    await Amplify.Auth.signInWithWebUI(provider: AuthProvider.google);
  }

  Future<void> signOut() async {
    try {
      await ref.read(cloudRepositoryProvider).clearFcmToken();
    } catch (e) {
      debugPrint('Failed to clear FCM token: $e');
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Failed to delete FCM token: $e');
    }
    await Amplify.Auth.signOut(
      options: const SignOutOptions(globalSignOut: true),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => Amplify.Auth.getCurrentUser());
  }
}
