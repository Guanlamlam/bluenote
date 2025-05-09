import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bluenote/screens/chat_screen.dart';
import 'package:bluenote/screens/auth/user_profile_screen_for_user.dart';
import 'package:bluenote/widgets/guanlam/bottom_nav_bar.dart';
import 'package:bluenote/screens/notifications_screen.dart';
import 'package:bluenote/service/firebase_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Stream<List<DocumentSnapshot>> _getChatrooms() {
    if (currentUser == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('chatrooms')
        .where('participants', arrayContains: currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      docs.sort((a, b) {
        final aTime = a['lastTimestamp'] as Timestamp?;
        final bTime = b['lastTimestamp'] as Timestamp?;
        return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
      });
      return docs;
    });
  }

  // Use StreamBuilder to update the unread count in real-time
  Stream<int> _getUnreadCountForNotifications() {
    if (currentUser == null) return Stream.value(0); // Return default 0 if no current user

    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('notifications')
        .where('viewed', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.length;
    });
  }

  Future<Map<String, dynamic>> _getOtherUserData(List<dynamic> participants) async {
    try {
      final otherUserId = participants.firstWhere(
            (id) => id != currentUser!.uid,
      ) as String;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      return userDoc.data() ?? {};
    } catch (e) {
      print("Error fetching other user data: $e");
      return {};
    }
  }

  Future<void> _deleteConversation(String chatroomId) async {
    try {
      await FirebaseFirestore.instance.collection('chatrooms').doc(chatroomId).delete();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> deletedChatrooms = prefs.getStringList('deleted_chatrooms') ?? [];
      deletedChatrooms.add(chatroomId);
      await prefs.setStringList('deleted_chatrooms', deletedChatrooms);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete conversation: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List'),
        actions: [
          // Notification Icon with unread count
          StreamBuilder<int>(
            stream: _getUnreadCountForNotifications(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(3), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16), // Smaller badge
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10, // Smaller font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationsScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getChatrooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No chat records yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final chatroom = snapshot.data![index];
              final participants = chatroom['participants'] as List<dynamic>;
              final lastMessage = chatroom['lastMessage'] ?? '';
              final lastTimestamp = chatroom['lastTimestamp'] as Timestamp?;
              final chatroomId = chatroom.id;

              return FutureBuilder<Map<String, dynamic>>(
                future: _getOtherUserData(participants),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data ?? {};
                  final username = userData['username'] ?? 'Unknown User';
                  final profilePic = userData['profilePictureUrl'] ?? '';

                  return Dismissible(
                    key: Key(chatroomId),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) {
                      _deleteConversation(chatroomId);
                    },
                    background: Container(
                      color: Colors.red,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreenForUser(
                                uid: participants.firstWhere(
                                      (id) => id != currentUser!.uid,
                                ) as String,
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundImage: profilePic.isNotEmpty
                              ? NetworkImage(profilePic)
                              : const AssetImage('assets/default-profile.jpg') as ImageProvider,
                        ),
                      ),
                      title: Text(username),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastTimestamp != null)
                            Text(
                              DateFormat('MM/dd HH:mm').format(lastTimestamp.toDate()),
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatroomId: chatroom.id,
                              otherUserId: participants.firstWhere(
                                    (id) => id != currentUser!.uid,
                              ) as String,
                              otherUserName: username,
                              otherUserProfilePic: profilePic,
                              otherUserFcmToken: userData['fcmToken'] ?? '',
                            ),
                          ),
                        ).then((_) {
                          setState(() {});  // Refresh on return
                        });
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}
