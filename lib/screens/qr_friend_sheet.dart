import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/app_providers.dart';

class QrFriendSheet extends ConsumerStatefulWidget {
  final void Function(String username) onScanned;

  const QrFriendSheet({super.key, required this.onScanned});

  @override
  ConsumerState<QrFriendSheet> createState() => _QrFriendSheetState();
}

class _QrFriendSheetState extends ConsumerState<QrFriendSheet> {
  bool _showMyQr = false;
  bool _scanned = false;
  late final MobileScannerController _scanner;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _scanned = true;
    Navigator.of(context).pop();
    widget.onScanned(code);
  }

  void _toggleTab(bool showMyQr) {
    setState(() => _showMyQr = showMyQr);
    if (showMyQr) {
      _scanner.stop();
    } else {
      _scanner.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Scan')),
                ButtonSegment(value: true, label: Text('My QR')),
              ],
              selected: {_showMyQr},
              onSelectionChanged: (v) => _toggleTab(v.first),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _showMyQr
                    ? const _MyQrCode()
                    : MobileScanner(
                        controller: _scanner,
                        onDetect: _onDetect,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MyQrCode extends ConsumerWidget {
  const _MyQrCode();

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
