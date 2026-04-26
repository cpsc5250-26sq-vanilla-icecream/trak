import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'edit_user_profile_page.dart';

class UserProfilePage extends StatelessWidget {
  final UserProfile profile;
  const UserProfilePage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(profile.username)),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
              ),
              // Username
              const SizedBox(height: 8),
              Text(
                '@${profile.username}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              // Display Name
              const SizedBox(height: 24),
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(profile: profile),
                    ),
                  );
                },
                child: Text("Edit Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
