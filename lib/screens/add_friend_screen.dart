import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

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
            // TODO: QR IMPLEMENTATION
            onPressed: () {
              // TODO: Open QR + Camera to open QR SCANNER
              // CAMERA SCANNER MAY REQUIRE PERMISSIONS TO BE ACTIVATED
            },
            icon: Icon(Icons.qr_code_rounded),
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
                    : const Text('Add Friend'),
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
                Text('$_successName added!'),
              ],
              const SizedBox(height: 24),
              Center(
                child: Text(
                  "Your Friends",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const _FriendListCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendListCard extends ConsumerWidget {
  const _FriendListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(repositoryProvider);
    return FutureBuilder<List<dynamic>>(
      future: repository.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(snapshot.error.toString()),
          );
        }

        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(24),
            child: Text("No friends yet :("),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(child: Icon(Icons.person_2_rounded)),
              title: Text(friends[index]["friendId"] ?? "Unknown"),
            );
          },
        );
      },
    );
  }
}
