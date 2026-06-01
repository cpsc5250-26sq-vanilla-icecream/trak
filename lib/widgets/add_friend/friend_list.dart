import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/friend.dart';
import '../../providers/app_providers.dart';

class FriendList extends ConsumerWidget {
  const FriendList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    return friendsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          Padding(padding: const EdgeInsets.all(24), child: Text(e.toString())),
      data: (friends) {
        if (friends.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No friends yet :('),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friends.length,
          itemBuilder: (_, index) => _FriendTile(friends[index]),
        );
      },
    );
  }
}

class _FriendTile extends ConsumerWidget {
  final Friend friend;
  const _FriendTile(this.friend);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_2_rounded)),
      title: Text(friend.displayName ?? friend.username ?? friend.friendId),
      subtitle: friend.username != null ? Text('@${friend.username}') : null,
      trailing: IconButton(
        icon: const Icon(Icons.person_remove_rounded),
        color: Theme.of(context).colorScheme.error,
        tooltip: 'Remove friend',
        onPressed: () async {
          if (await _confirm(context, friend)) {
            await ref.read(repositoryProvider).removeFriend(friend.friendId);
            ref.invalidate(friendsProvider);
          }
        },
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, Friend friend) async {
    final name = friend.displayName ?? friend.username ?? friend.friendId;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove friend?'),
            content: Text('Remove $name?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Remove',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
