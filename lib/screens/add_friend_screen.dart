import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend.dart';
import '../models/friend_request.dart';
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
      if (!mounted) return;
      ref.invalidate(friendsProvider);
      setState(() {
        _successName = username;
        _loading = false;
        _controller.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showQrSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => QrFriendSheet(
        onScanned: (username) {
          _controller.text = username;
          _submit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        actions: [
          IconButton(
            onPressed: _showQrSheet,
            icon: const Icon(Icons.qr_code_rounded),
            iconSize: 32,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddFriendForm(
              controller: _controller,
              loading: _loading,
              error: _error,
              successName: _successName,
              onSubmit: _submit,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Pending Requests'),
            const SizedBox(height: 8),
            const _FriendRequestList(),
            const SizedBox(height: 24),
            const _SectionTitle('Your Friends'),
            const _FriendList(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _AddFriendForm extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final String? successName;
  final VoidCallback onSubmit;

  const _AddFriendForm({
    required this.controller,
    required this.loading,
    required this.error,
    required this.successName,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Enter a username',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          enabled: !loading,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Request'),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (successName != null) ...[
          const SizedBox(height: 12),
          Text('Request sent to $successName!'),
        ],
      ],
    );
  }
}

class _FriendRequestList extends ConsumerWidget {
  const _FriendRequestList();

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

class _FriendList extends ConsumerWidget {
  const _FriendList();

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
          final confirmed = await _confirmRemoveFriend(
            context,
            friend.displayName ?? friend.username ?? friend.friendId,
          );

          if (confirmed) {
            await ref.read(repositoryProvider).removeFriend(friend.friendId);

            ref.invalidate(friendsProvider);
          }
        },
      ),
    );
  }
}

Future<bool> _confirmRemoveFriend(BuildContext context, String name) async {
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
