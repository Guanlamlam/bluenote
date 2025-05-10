import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bluenote/widgets/yanqi/edit_profile_button.dart';
import 'package:bluenote/widgets/yanqi/tabs.dart';
import 'package:bluenote/screens/auth/login_screen.dart';
import 'package:bluenote/screens/chat_screen.dart';

import '../../widgets/guanlam/bottom_nav_bar.dart';

class UserProfileScreenForUser extends StatelessWidget {
  final String uid;  // The UID of the user whose profile is being viewed

  const UserProfileScreenForUser({required this.uid, super.key});

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print("Error fetching user data: $e");
      return {};
    }
  }

  String _generateConversationId(String user1Uid, String user2Uid) {
    if (user1Uid.isEmpty || user2Uid.isEmpty) {
      throw Exception("User IDs must not be empty!");
    }
    List<String> sortedUids = [user1Uid, user2Uid]..sort();
    return '${sortedUids[0]}_${sortedUids[1]}';
  }

  Future<String> _getOrCreateChatroom(String currentUserId, String otherUserId) async {
    final conversationId = _generateConversationId(currentUserId, otherUserId);

    final chatroomDoc = await FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(conversationId)
        .get();

    if (!chatroomDoc.exists) {
      await FirebaseFirestore.instance.collection('chatrooms').doc(conversationId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    }

    return conversationId;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getUserData(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No user data available.'));
              }

              var userData = snapshot.data!;
              String username = userData['username'] ?? 'Username not found';
              String profilePictureUrl = userData['profilePictureUrl'] ?? '';
              String bio = userData['bio'] ?? 'No bio available';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profilePictureUrl.isNotEmpty
                            ? NetworkImage(profilePictureUrl)
                            : const AssetImage('assets/default-profile.jpg') as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        username,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Bio: $bio',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Get or create chatroom and get its ID
                        final chatroomId = await _getOrCreateChatroom(currentUser.uid, uid);

                        // Navigate to chat screen with all required information
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatroomId: chatroomId,  // 使用获取到的chatroomId
                              otherUserId: uid,
                              otherUserName: username,
                              otherUserProfilePic: profilePictureUrl,
                              otherUserFcmToken: userData['fcmToken'] ?? '', // Add this
                            ),
                          ),
                        );
                      } catch (e) {
                        print("Error: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error starting chat: $e')),
                        );
                      }
                    },
                    child: const Text('Send Message'),
                  ),
                  const SizedBox(height: 20),

                  Tabs(selectedTab: 'Post', userId: uid),
                ],
              );
            },
          ),
        ),
      ),
      // bottomNavigationBar: BottomNavBar(),
    );
  }
}