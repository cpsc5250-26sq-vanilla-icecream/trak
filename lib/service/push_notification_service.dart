import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'Background message received: '
    '${message.notification?.title}',
  );
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
        debugPrint('Foreground message: ${message.notification?.title}');
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
