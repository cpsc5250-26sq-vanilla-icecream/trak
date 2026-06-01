import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/add_friend/add_friend_form.dart';
import '../widgets/add_friend/friend_list.dart';
import '../widgets/add_friend/friend_request_list.dart';
import 'qr_friend_sheet.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});
  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error, _successName;

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
    if (username.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _successName = null;
    });
    try {
      await ref.read(repositoryProvider).addFriend(username);
      if (!mounted) {
        return;
      }
      ref.invalidate(friendsProvider);
      setState(() {
        _successName = username;
        _loading = false;
        _controller.clear();
      });
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
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => QrFriendSheet(
                onScanned: (u) {
                  _controller.text = u;
                  _submit();
                },
              ),
            ),
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
            AddFriendForm(
              controller: _controller,
              loading: _loading,
              error: _error,
              successName: _successName,
              onSubmit: _submit,
            ),
            const SizedBox(height: 24),
            Center(child: Text('Pending Requests', style: titleStyle)),
            const SizedBox(height: 8),
            const FriendRequestList(),
            const SizedBox(height: 24),
            Center(child: Text('Your Friends', style: titleStyle)),
            const FriendList(),
          ],
        ),
      ),
    );
  }
}
