import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../repository/cloud_repository.dart';
import '../widgets/username_form.dart';

class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool loading = false;
  String? serverError;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => serverError = null);

    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await ref
          .read(cloudRepositoryProvider)
          .setUsername(controller.text.trim());

      ref.invalidate(needsUsernameProvider);
    } on UsernameAlreadyTakenException {
      setState(() => serverError = 'Username already taken');
    } catch (_) {
      setState(() => serverError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => UsernameForm(
    controller: controller,
    formKey: formKey,
    loading: loading,
    serverError: serverError,
    onSubmit: submit,
  );
}