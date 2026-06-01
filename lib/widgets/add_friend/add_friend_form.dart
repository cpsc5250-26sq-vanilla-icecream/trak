import 'package:flutter/material.dart';

class AddFriendForm extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final String? successName;
  final VoidCallback onSubmit;

  const AddFriendForm({
    super.key,
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
