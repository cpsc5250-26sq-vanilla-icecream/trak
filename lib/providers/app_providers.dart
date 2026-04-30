import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../auth/jwt_utils.dart';
import '../models/leaderboard_entry.dart';
import '../models/inventory_item.dart';
import '../models/user_profile.dart';
import '../repository/app_repository.dart';
import '../repository/cloud_repository.dart';
import '../repository/health_repository.dart';
import '../repository/sqflite_app_repository.dart';
import '../sync/sync_service.dart';

final idTokenProvider = FutureProvider<String>((ref) async {
  final session = await Amplify.Auth.fetchAuthSession();
  if (session is! CognitoAuthSession) {
    throw Exception('Not signed in or unexpected session type');
  }
  return session.userPoolTokensResult.value.idToken.raw;
});

final sqfliteRepositoryProvider = Provider<SqfliteAppRepository>(
  (_) => SqfliteAppRepository(),
);

final cloudRepositoryProvider = Provider<CloudRepository>(
  (_) => CloudRepository(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    health: HealthRepository(),
    cloud: ref.watch(cloudRepositoryProvider),
    repo: ref.watch(sqfliteRepositoryProvider),
  );
});

// This is just the API, throws an error if not overridden
final repositoryProvider = Provider<AppRepository>(
  (_) => throw UnimplementedError('repositoryProvider must be overridden'),
);

final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>(
  (ref) => ref.watch(repositoryProvider).watchLeaderboard(),
);

final inventoryProvider = StreamProvider<List<InventoryItem>>(
  (ref) => ref.watch(repositoryProvider).watchInventory(),
);

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
