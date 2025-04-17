import 'package:flutter/material.dart';
import 'package:bluenote/widgets/yanqi/profile_picture.dart';
import 'package:bluenote/widgets/yanqi/edit_profile_button.dart';
import 'package:bluenote/widgets/yanqi/tabs.dart';
import 'package:bluenote/widgets/yanqi/post_section.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User 2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings logic here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            const ProfilePicture(),
            const SizedBox(height: 16),
            const EditProfileButton(),
            const SizedBox(height: 20),

            // Tabs for Post and Liked
            const Tabs(selectedTab: 'Post'),
            const SizedBox(height: 20),

            // Post Section
            const PostSection(),
          ],
        ),
      ),
    );
  }
}
