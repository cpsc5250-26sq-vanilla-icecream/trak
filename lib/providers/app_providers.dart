import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_entry.dart';
import '../models/inventory_item.dart';
import '../models/user_profile.dart';
import '../repository/app_repository.dart';

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

final currentUserProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(repositoryProvider).getCurrentUser(),
);
