import 'package:flutter/material.dart';
import '../service/local_notification_service.dart';

class TestNotificationButton extends StatelessWidget {
  const TestNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await LocalNotificationService.showNotification();
      },
      child: const Text('Push Test Notification'),
    );
  }
}
