import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trak/models/avatar_upload_response.dart';
import 'package:trak/models/friend.dart';
import 'package:trak/models/friend_request.dart';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';
import 'package:trak/models/use_item_result.dart';
import 'package:trak/models/user_profile.dart';
import 'package:trak/providers/app_providers.dart';
import 'package:trak/repository/app_repository.dart';
import 'package:trak/screens/edit_profile_screen.dart';

Widget _wrap({UserProfile? profile}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith(
        (ref) async =>
            profile ??
            const UserProfile(
              userId: 'user-1',
              username: 'tester',
              displayName: 'Kyle',
            ),
      ),
    ],
    child: const MaterialApp(home: EditProfileScreen()),
  );
}

class FakeRepository implements AppRepository {
  bool updateDisplayNameCalled = false;
  String? savedName;

  @override
  Future<void> updateDisplayName(String name) async {
    updateDisplayNameCalled = true;
    savedName = name;
  }

  @override
  Stream<int> watchStepCount() => Stream.value(0);

  @override
  Stream<List<Friend>> watchFriends() => Stream.value([]);

  @override
  Stream<DateTime?> watchResetTime() => const Stream.empty();

  @override
  Stream<List<InventoryItem>> watchInventory() => Stream.value([]);

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard() => Stream.value([]);

  @override
  Future<UserProfile> getCurrentUser() async {
    throw UnimplementedError();
  }

  @override
  Future<void> putSteps(int stepCount) async {}

  @override
  Future<void> addFriend(String username) async {}

  @override
  Future<void> removeFriend(String friendId) async {}

  @override
  Future<void> acceptFriendRequest(String fromUserId) async {}

  @override
  Future<void> declineFriendRequest(String fromUserId) async {}

  @override
  Future<void> updateAvatarUrl(String avatarUrl) async {}

  @override
  Future<List<FriendRequest>> getFriendRequests() async => [];

  @override
  Future<List<LeaderboardEntry>> fetchHistoricalLeaderboard(
    String date,
  ) async => [];

  @override
  Future<AvatarUploadResponse> getAvatarUploadUrl(String contentType) async {
    throw UnimplementedError();
  }

  @override
  Future<UseItemResult> useItem(String itemId, String targetUserId) async {
    throw UnimplementedError();
  }
}

class FailingRepository extends FakeRepository {
  @override
  Future<void> updateDisplayName(String name) async {
    throw Exception('fail');
  }
}

void main() {
  group('EditProfileScreen', () {
    testWidgets('shows edit profile title on screen', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('shows change avatar button', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.pumpAndSettle();

      expect(find.text('Change Avatar'), findsOneWidget);
    });

    testWidgets('shows save changes button', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.pumpAndSettle();

      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('shows display name field', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Kyle'), findsOneWidget);
    });

    testWidgets('loads display name from profile', (tester) async {
      await tester.pumpWidget(
        _wrap(
          profile: const UserProfile(
            userId: 'user-1',
            username: 'tester',
            displayName: 'Kyle Taylor',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Kyle Taylor'), findsOneWidget);
    });

    testWidgets('uses username when display name is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          profile: const UserProfile(
            userId: 'user-1',
            username: 'tester',
            displayName: '',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('tester'), findsOneWidget);
    });

    testWidgets('shows avatar icon when avatar url is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          profile: const UserProfile(
            userId: 'user-1',
            username: 'tester',
            displayName: 'Kyle',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows camera icon on avatar section', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('shows validation error when display name is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');

      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(find.text('Display name cannot be empty'), findsOneWidget);
    });

    testWidgets('save button calls updateDisplayName', (tester) async {
      final repo = FakeRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            currentUserProvider.overrideWith(
              (ref) async => const UserProfile(
                userId: 'user-1',
                username: 'tester',
                displayName: 'Kyle',
              ),
            ),
          ],
          child: const MaterialApp(home: EditProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New Name');

      await tester.tap(find.text('Save Changes'));

      await tester.pumpAndSettle();

      expect(repo.updateDisplayNameCalled, isTrue);
      expect(repo.savedName, 'New Name');
    });

    testWidgets('shows snackbar when save fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(FailingRepository()),
            currentUserProvider.overrideWith(
              (ref) async => const UserProfile(
                userId: 'user-1',
                username: 'tester',
                displayName: 'Kyle',
              ),
            ),
          ],
          child: const MaterialApp(home: EditProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));

      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to save profile'), findsOneWidget);
    });
  });
}
