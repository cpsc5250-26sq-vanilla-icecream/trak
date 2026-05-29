import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/leaderboard_entry.dart';
import '../models/inventory_item.dart';
import '../models/user_profile.dart';
import '../repository/app_repository.dart';
import '../repository/caching_app_repository.dart';
import '../repository/cloud_repository.dart';
import '../repository/health_repository.dart';
import '../repository/mock_app_repository.dart';
import '../repository/sqf_repository.dart';
import '../sync/sync_service.dart';

final idTokenProvider = FutureProvider<String>((ref) async {
  final session = await Amplify.Auth.fetchAuthSession();
  if (session is! CognitoAuthSession) {
    throw Exception('Not signed in or unexpected session type');
  }
  return session.userPoolTokensResult.value.idToken.raw;
});

final sqfRepositoryProvider = Provider<SqfRepository>((_) => SqfRepository());

final cloudRepositoryProvider = Provider<CloudRepository>(
  (_) => CloudRepository(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    health: HealthRepository(),
    cloud: ref.watch(cloudRepositoryProvider),
    repo: ref.watch(sqfRepositoryProvider),
  );
});

class UseMockNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final useMockProvider = NotifierProvider<UseMockNotifier, bool>(
  UseMockNotifier.new,
);

final repositoryProvider = Provider<AppRepository>((ref) {
  if (kDebugMode && ref.watch(useMockProvider)) {
    final mock = MockAppRepository();
    ref.onDispose(mock.dispose);
    return mock;
  }
  return CachingAppRepository(
    cloud: ref.watch(cloudRepositoryProvider),
    cache: ref.watch(sqfRepositoryProvider),
  );
});

final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>(
  (ref) => ref.watch(repositoryProvider).watchLeaderboard(),
);

final historicalLeaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>(
  (ref, date) => ref.watch(cloudRepositoryProvider).fetchLeaderboard(date: date),
);

final inventoryProvider = StreamProvider<List<InventoryItem>>(
  (ref) => ref.watch(repositoryProvider).watchInventory(),
);

final friendsProvider = StreamProvider<List<Friend>>(
  (ref) => ref.watch(repositoryProvider).watchFriends(),
);

final friendRequestsProvider = FutureProvider<List<FriendRequest>>(
  (ref) => ref.watch(repositoryProvider).getFriendRequests(),
);

final stepCountProvider = StreamProvider<int>(
  (ref) => ref.watch(repositoryProvider).watchStepCount(),
);

final needsUsernameProvider = FutureProvider<bool>((ref) async {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser == null) return false;
  if (kDebugMode && ref.watch(useMockProvider)) return false;
  final profile = await ref.read(cloudRepositoryProvider).getCurrentUser();
  return profile.username.isEmpty;
});

final currentUserPointsProvider = Provider<int>((ref) {
  final userId = ref.watch(currentUserProvider).asData?.value.userId;
  final entries = ref.watch(leaderboardProvider).asData?.value ?? [];
  if (userId == null) return 0;
  return entries
          .where((e) => e.userId == userId)
          .map((e) => e.totalPoints)
          .firstOrNull ??
      0;
});

final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser == null) throw Exception('Not signed in');
  return ref.watch(repositoryProvider).getCurrentUser();
});
