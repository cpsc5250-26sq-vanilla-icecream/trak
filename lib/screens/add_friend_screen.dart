import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'qr_friend_sheet.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successName;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(friendRequestsProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _successName = null;
    });

    try {
      await ref.read(repositoryProvider).addFriend(username);
      if (mounted) {
        ref.invalidate(friendsProvider);
        setState(() {
          _successName = username;
          _loading = false;
          _controller.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => QrFriendSheet(
                  onScanned: (username) {
                    _controller.text = username;
                    _submit();
                  },
                ),
              );
            },
            icon: const Icon(Icons.qr_code_rounded),
            iconSize: 32,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter a username',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                enabled: !_loading,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Request'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_successName != null) ...[
                const SizedBox(height: 12),
                Text('Request sent to $_successName!'),
              ],
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Pending Requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              const _FriendRequestList(),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Your Friends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const _FriendList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendRequestList extends ConsumerWidget {
  const _FriendRequestList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error.toString()),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No pending requests',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person_add_rounded),
              ),
              title: Text(req.fromDisplayName ?? req.fromUsername),
              subtitle: Text('@${req.fromUsername}'),
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
                          .acceptFriendRequest(req.fromUserId);
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
                          .declineFriendRequest(req.fromUserId);
                      ref.invalidate(friendRequestsProvider);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FriendList extends ConsumerWidget {
  const _FriendList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    return friendsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(error.toString()),
      ),
      data: (friends) {
        if (friends.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No friends yet :(',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_2_rounded)),
              title: Text(
                friend.displayName ?? friend.username ?? friend.friendId,
              ),
              subtitle: friend.username != null
                  ? Text('@${friend.username}')
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.person_remove_rounded),
                color: Theme.of(context).colorScheme.error,
                tooltip: 'Remove friend',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remove friend?'),
                      content: Text(
                        'Remove ${friend.displayName ?? friend.username ?? friend.friendId}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref
                        .read(repositoryProvider)
                        .removeFriend(friend.friendId);
                    ref.invalidate(friendsProvider);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
