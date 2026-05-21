import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _requestPermission();
    await _printToken();
    _listenForeground();
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission();

    debugPrint(
      'Permission: ${settings.authorizationStatus}',
    );
  }

  static Future<void> _printToken() async {
    final token = await _messaging.getToken();

    debugPrint('FCM TOKEN: $token');
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