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

    Future.microtask(() async {
      final profile = await ref.read(currentUserProvider.future);

      if (!mounted) return;

      setState(() {
        _displayNameController.text = profile.displayName;
        _avatarUrl = profile.avatarUrl;
      });
    });
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      final repo = ref.read(repositoryProvider);

      final uploadInfo = await repo.getAvatarUploadUrl('image/jpeg');

      // Skip upload when using mock repo
      if (uploadInfo.uploadUrl != 'mock-upload-url') {
        final bytes = await File(picked.path).readAsBytes();

        final response = await http.put(
          Uri.parse(uploadInfo.uploadUrl),
          headers: {'Content-Type': uploadInfo.contentType},
          body: bytes,
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Avatar upload failed');
        }
      }

      await repo.updateAvatarUrl(uploadInfo.publicUrl);

      ref.invalidate(currentUserProvider);

      if (mounted) {
        setState(() {
          _avatarUrl = uploadInfo.publicUrl;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update avatar: $e')));
    }
  }

  Future<void> _save() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) return;
    setState(() {
      _loading = true;
    });
    try {
      await ref.read(repositoryProvider).updateDisplayName(displayName);
      ref.invalidate(currentUserProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? const Icon(Icons.person, size: 55)
                        : null,
                  ),
                  Positioned(
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

            const SizedBox(height: 12),

            TextButton(
              onPressed: _pickAvatar,
              child: const Text('Change Avatar'),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
