import 'package:flutter/material.dart';
import 'package:trak/models/user_profile.dart';

// TODO: EDIT PROFILE IMPLEMENTATION
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key, required UserProfile profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(children: []),
      ),
    );
  }
}
