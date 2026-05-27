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

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _printToken();
    _listenForeground();
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission();

    debugPrint('Permission: ${settings.authorizationStatus}');
  }

  static Future<void> _printToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM TOKEN: $token');
    } catch (e) {
      debugPrint('FCM token not yet available: $e');
    }
  }

  static void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'Foreground message: '
        '${message.notification?.title}',
      );
    });
  }
}
