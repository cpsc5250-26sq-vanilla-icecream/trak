import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/app_providers.dart';

class MyQrCode extends ConsumerWidget {
  const MyQrCode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (user) {
        if (user.username.isEmpty) {
          return const Center(child: Text('Set a username first'));
        }
        return Center(child: QrImageView(data: user.username, size: 250));
      },
    );
  }
}
