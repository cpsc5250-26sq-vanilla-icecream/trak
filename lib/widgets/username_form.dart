import 'package:flutter/material.dart';

class UsernameForm extends StatelessWidget {
  UsernameForm({
    super.key,
    required this.controller,
    required this.formKey,
    required this.loading,
    required this.serverError,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final bool loading;
  final String? serverError;
  final VoidCallback onSubmit;

  static final _pattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a username')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pick a unique username. This will be your public identity in Trak.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'letters, numbers, underscores',
                  errorText: serverError,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                validator: (v) {
                  final value = v?.trim() ?? '';

                  if (value.isEmpty) return 'Username is required';
                  if (!_pattern.hasMatch(value)) {
                    return '3–20 characters: letters, numbers, and underscores only';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: loading ? null : onSubmit,
                child: loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}