import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../auth/jwt_utils.dart';
import '../models/friend.dart';
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

final inventoryProvider = StreamProvider<List<InventoryItem>>(
  (ref) => ref.watch(repositoryProvider).watchInventory(),
);

final friendsProvider = FutureProvider<List<Friend>>((ref) async {
  return ref.watch(repositoryProvider).getFriends();
});

final stepCountProvider = StreamProvider<int>(
  (ref) => ref.watch(repositoryProvider).watchStepCount(),
);

final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser == null) throw Exception('Not signed in');

  final raw = await ref.watch(idTokenProvider.future);
  final claims = JwtUtils.decodeClaims(raw);

  return UserProfile(
    userId: authUser.userId,
    username: authUser.username,
    displayName: claims['name'] as String? ?? authUser.username,
    avatarUrl: claims['picture'] as String?,
  );
});
