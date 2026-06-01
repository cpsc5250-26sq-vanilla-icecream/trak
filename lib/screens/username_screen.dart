import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../repository/cloud_repository.dart';

class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _UsernameController _username;

  @override
  void initState() {
    super.initState();
    _username = _UsernameController(ref);
  }

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a username')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _UsernameForm(
          formKey: _formKey,
          controller: _username,
          onSubmit: () => _username.submit(_formKey, _refresh),
        ),
      ),
    );
  }
}

class _UsernameController {
  final WidgetRef ref;
  final controller = TextEditingController();

  bool loading = false;
  String? serverError;

  static final validPattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  _UsernameController(this.ref);

  Future<void> submit(
    GlobalKey<FormState> formKey,
    VoidCallback refresh,
  ) async {
    serverError = null;
    refresh();

    if (!formKey.currentState!.validate()) return;

    loading = true;
    refresh();

    try {
      await ref
          .read(cloudRepositoryProvider)
          .setUsername(controller.text.trim());

      ref.invalidate(needsUsernameProvider);
    } on UsernameAlreadyTakenException {
      serverError = 'Username already taken';
    } catch (_) {
      serverError = 'Something went wrong. Please try again.';
    }

    loading = false;
    refresh();
  }

  void dispose() => controller.dispose();
}

class _UsernameForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final _UsernameController controller;
  final VoidCallback onSubmit;

  const _UsernameForm({
    required this.formKey,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
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
            controller: controller.controller,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'letters, numbers, underscores',
              errorText: controller.serverError,
              border: const OutlineInputBorder(),
            ),
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }

              if (!_UsernameController.validPattern.hasMatch(value.trim())) {
                return '3–20 characters: letters, numbers, and underscores only';
              }

              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: controller.loading ? null : onSubmit,
            child: controller.loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
