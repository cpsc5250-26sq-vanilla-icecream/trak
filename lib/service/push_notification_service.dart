import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../background/step_sync_task.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['type'] == 'step_sync') {
    try {
      await pushSteps();
    } catch (e) {
      debugPrint('Background step sync error: $e');
    }
  }
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  // Call once at startup. Safe to call again — subsequent calls are no-ops for
  // listeners but always return the current token.
  static Future<String?> initialize({
    void Function(String token)? onTokenRefresh,
  }) async {
    if (!_initialized) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _requestPermission();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen((message) {
        if (message.data['type'] == 'step_sync') {
          pushSteps().catchError((e) {
            debugPrint('Foreground step sync error: $e');
          });
        }
      });
      _initialized = true;
    }

    if (onTokenRefresh != null) {
      _messaging.onTokenRefresh.listen(onTokenRefresh);
    }

    String? token;
    try {
      token = await _messaging.getToken();
      debugPrint('FCM TOKEN: $token');
    } catch (e) {
      debugPrint('FCM token not yet available: $e');
    }
    return token;
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission();
    debugPrint('Permission: ${settings.authorizationStatus}');
  }
}
