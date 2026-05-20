import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:trak/models/user_profile.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/screens/qr_friend_sheet.dart';

Widget _wrap({required UserProfile user, void Function(String)? onScanned}) =>
    ProviderScope(
      overrides: [currentUserProvider.overrideWith((_) async => user)],
      child: MaterialApp(
        home: Scaffold(body: QrFriendSheet(onScanned: onScanned ?? (_) {})),
      ),
    );

const _user = UserProfile(
  userId: 'u1',
  username: 'alice',
  displayName: 'Alice',
);

const _noUsername = UserProfile(
  userId: 'u2',
  username: '',
  displayName: 'New User',
);

void main() {
  group('QrFriendSheet', () {
    testWidgets('defaults to Scan tab', (tester) async {
      await tester.pumpWidget(_wrap(user: _user));
      final button = tester.widget<SegmentedButton<bool>>(
        find.byType(SegmentedButton<bool>),
      );
      expect(button.selected, {false});
    });

    testWidgets('switching to My QR tab shows QrImageView', (tester) async {
      await tester.pumpWidget(_wrap(user: _user));
      await tester.tap(find.text('My QR'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('My QR shows fallback when username is empty', (tester) async {
      await tester.pumpWidget(_wrap(user: _noUsername));
      await tester.tap(find.text('My QR'));
      await tester.pumpAndSettle();
      expect(find.text('Set a username first'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });
  });
}
