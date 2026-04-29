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
      appBar: AppBar(title: const Text('Add Friend')),
      body: Padding(
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
          ],
        ),
      ),
    );
  }
}
