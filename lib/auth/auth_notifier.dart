import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/cloud_repository.dart';

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final subscription = Amplify.Hub.listen(HubChannel.Auth, (event) async {
      if (event.type == AuthHubEventType.signedIn) {
        final token = await FirebaseMessaging.instance.getToken();
        debugPrint('TOKEN AFTER LOGIN: $token');
        if (token != null) {
          try {
            await CloudRepository().saveFcmToken(token);
            debugPrint('TOKEN SAVED TO BACKEND');
          } catch (e) {
            debugPrint('Failed to save token: $e ');
          }
        }
        await refresh();
      } else if (event.type == AuthHubEventType.signedOut) {
        state = const AsyncData(null);
      }
    });
    ref.onDispose(subscription.cancel);

    try {
      return await Amplify.Auth.getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    await Amplify.Auth.signInWithWebUI(provider: AuthProvider.google);
  }

  Future<void> signOut() async {
    await Amplify.Auth.signOut(
      options: const SignOutOptions(globalSignOut: true),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => Amplify.Auth.getCurrentUser());
  }
}
