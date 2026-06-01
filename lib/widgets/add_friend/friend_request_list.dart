import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/friend_request.dart';
import '../../providers/app_providers.dart';

class FriendRequestList extends ConsumerWidget {
  const FriendRequestList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);

    return requestsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          Padding(padding: const EdgeInsets.all(16), child: Text(e.toString())),
      data: (requests) {
        if (requests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No pending requests'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (_, index) => _FriendRequestTile(requests[index]),
        );
      },
    );
  }
}

class _FriendRequestTile extends ConsumerWidget {
  final FriendRequest request;
  const _FriendRequestTile(this.request);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_add_rounded)),
      title: Text(request.fromDisplayName ?? request.fromUsername),
      subtitle: Text('@${request.fromUsername}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle_rounded),
            color: Colors.green,
            tooltip: 'Accept',
            onPressed: () async {
              await ref
                  .read(repositoryProvider)
                  .acceptFriendRequest(request.fromUserId);
              ref.invalidate(friendRequestsProvider);
              ref.invalidate(friendsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel_rounded),
            color: Theme.of(context).colorScheme.error,
            tooltip: 'Decline',
            onPressed: () async {
              await ref
                  .read(repositoryProvider)
                  .declineFriendRequest(request.fromUserId);
              ref.invalidate(friendRequestsProvider);
            },
          ),
        ],
      ),
    );
  }
}
