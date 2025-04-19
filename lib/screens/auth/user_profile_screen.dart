import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bluenote/widgets/yanqi/edit_profile_button.dart'; // Edit profile button
import 'package:bluenote/widgets/yanqi/tabs.dart'; // Tab widget for 'Post' and 'Liked'
import 'package:bluenote/screens/auth/login_screen.dart'; // Login screen for when user is not logged in

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  // Method to handle logout
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // After signing out, navigate back to the LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  // Fetch user data from Firestore
  Future<Map<String, dynamic>> _getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print("Error fetching user data: $e");
      return {};  // Return an empty map in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user is logged in, redirect to LoginScreen
      return const LoginScreen();
    }

    // Fetch user data from Firestore based on the user ID
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Settings'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _logout(context),
                            splashColor: Colors.blue.withOpacity(0.2),
                            highlightColor: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Log Out',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close settings dialog
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section: Fetch and display data
            FutureBuilder<Map<String, dynamic>>(
              future: _getUserData(user.uid), // Get user data from Firestore
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator()); // Show loading spinner while fetching
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No user data available.'));
                }

                // User data fetched successfully
                var userData = snapshot.data!;
                String username = userData['username'] ?? 'Username not found';
                String profilePictureUrl = userData['profilePictureUrl'] ?? ''; // Assuming URL is stored in Firestore
                String bio = userData['bio'] ?? 'No bio available'; // Default bio text if empty

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture and Username
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profilePictureUrl.isNotEmpty
                              ? NetworkImage(profilePictureUrl) // Load profile picture from URL
                              : const AssetImage('assets/default-profile.jpg') as ImageProvider, // Default image
                        ),
                        const SizedBox(width: 16),
                        Text(
                          username,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Display Bio
                    Text(
                      'Bio: $bio',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),

                    // Edit Profile Button
                    const EditProfileButton(),
                    const SizedBox(height: 20),

                    // Tabs for Post and Liked
                    const Tabs(selectedTab: 'Post'),  // Assuming you have a tabs widget for Post and Liked
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
