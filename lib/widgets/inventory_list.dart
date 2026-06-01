import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../providers/app_providers.dart';

class InventoryList extends ConsumerWidget {
  const InventoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return inventoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No powerups available'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) => _InventoryTile(items[index]),
        );
      },
    );
  }
}

class _InventoryTile extends ConsumerWidget {
  final InventoryItem item;

  const _InventoryTile(this.item);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Icon(
          item.type == ItemType.powerup ? Icons.arrow_upward : Icons.storm_rounded,
        ),
        title: Text(item.name),
        subtitle: Text(item.description),
        trailing: FilledButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => _UseItemDialog(item: item),
            );
          },
          child: const Text('Use'),
        ),
      ),
    );
  }
}

class _UseItemDialog extends ConsumerStatefulWidget {
  final InventoryItem item;

  const _UseItemDialog({required this.item});

  @override
  ConsumerState<_UseItemDialog> createState() => _UseItemDialogState();
}

class _UseItemDialogState extends ConsumerState<_UseItemDialog> {
  bool loading = false;
  String? selectedFriendId;

  Future<void> _useItem() async {
    setState(() => loading = true);

    final targetId = widget.item.type == ItemType.powerup
        ? ref.read(currentUserProvider).value!.userId
        : selectedFriendId;

    if (targetId == null) {
      setState(() => loading = false);
      return;
    }

    final result = await ref
        .read(repositoryProvider)
        .useItem(widget.item.itemId, targetId);

    if (!mounted) return;

    if (result.success) {
      ref.invalidate(inventoryProvider);
      ref.invalidate(leaderboardProvider);
      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${widget.item.name} used!')));
      return;
    }
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.errorMessage ?? 'Failed to use item')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.name),
      content: widget.item.type == ItemType.powerup
          ? const Text('Use on yourself?')
          : _FriendSelector(
              selectedFriendId: selectedFriendId,
              onChanged: (value) => setState(() => selectedFriendId = value),
            ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading ? null : _useItem,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(),
                )
              : const Text('Use'),
        ),
      ],
    );
  }
}

class _FriendSelector extends ConsumerWidget {
  final String? selectedFriendId;
  final ValueChanged<String?> onChanged;

  const _FriendSelector({
    required this.selectedFriendId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);

    return friendsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text(e.toString()),
      data: (friends) => DropdownButtonFormField<String>(
        initialValue: selectedFriendId,
        decoration: const InputDecoration(labelText: 'Target Friend'),
        items: friends
            .map(
              (friend) => DropdownMenuItem<String>(
                value: friend.friendId,
                child: Text(
                  friend.username ?? friend.friendId,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
