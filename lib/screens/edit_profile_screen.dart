import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../providers/app_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  String? _avatarUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProfile);
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(currentUserProvider.future);
    if (!mounted) return;
    setState(() {
      _displayNameController.text = profile.displayName.isNotEmpty
          ? profile.displayName
          : profile.username;
      _avatarUrl = profile.avatarUrl;
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _AvatarSection(
              avatarUrl: _avatarUrl,
              onChanged: (url) => setState(() => _avatarUrl = url),
              ref: ref,
            ),
            const SizedBox(height: 24),
            _DisplayNameField(controller: _displayNameController),
            const Spacer(),
            _SaveButton(
              loading: _loading,
              controller: _displayNameController,
              ref: ref,
              onLoadingChanged: (value) {
                setState(() => _loading = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.avatarUrl,
    required this.onChanged,
    required this.ref,
  });

  final String? avatarUrl;
  final WidgetRef ref;
  final ValueChanged<String?> onChanged;

  Future<void> _pickAvatar(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final repo = ref.read(repositoryProvider);
      final mimeType = picked.mimeType ?? 'image/jpeg';
      final upload = await repo.getAvatarUploadUrl(mimeType);
      if (upload.uploadUrl != 'mock-upload-url') {
        final bytes = await File(picked.path).readAsBytes();
        final response = await http.put(
          Uri.parse(upload.uploadUrl),
          headers: {'Content-Type': upload.contentType},
          body: bytes,
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Upload failed');
        }
      }
      await repo.updateAvatarUrl(upload.publicUrl);
      ref.invalidate(currentUserProvider);
      onChanged(upload.publicUrl);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update avatar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickAvatar(context),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 55)
                    : null,
              ),
              const Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.camera_alt, size: 18),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => _pickAvatar(context),
          child: const Text('Change Avatar'),
        ),
      ],
    );
  }
}

class _DisplayNameField extends StatelessWidget {
  const _DisplayNameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Display Name',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.loading,
    required this.controller,
    required this.ref,
    required this.onLoadingChanged,
  });

  final bool loading;
  final WidgetRef ref;
  final TextEditingController controller;
  final ValueChanged<bool> onLoadingChanged;

  Future<void> _save(BuildContext context) async {
    final name = controller.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }
    onLoadingChanged(true);
    try {
      await ref.read(repositoryProvider).updateDisplayName(name);
      ref.invalidate(currentUserProvider);
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      onLoadingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : () => _save(context),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              )
            : const Text('Save Changes'),
      ),
    );
  }
}
