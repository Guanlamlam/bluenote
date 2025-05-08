import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bluenote/screens/auth/UserProfileScreenForUser.dart';  // Import UserProfileScreenForUser
import 'package:bluenote/service/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatroomId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserProfilePic;
  final String otherUserFcmToken;

  const ChatScreen({
    required this.chatroomId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserProfilePic,
    required this.otherUserFcmToken,
    super.key,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _markMessagesAsRead();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (currentUser == null) return;

    final messages = await FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(widget.chatroomId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.otherUserId)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> _sendMessage() async {
    if (currentUser == null || _messageController.text.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('messages')
          .add({
        'senderId': currentUser!.uid,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false, // Messages start as unread
      });

      await FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .update({
        'lastMessage': _messageController.text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([currentUser!.uid, widget.otherUserId]),
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      try {
        await FirebaseService.instance.sendMessageWithImage(widget.chatroomId, imageFile);
      } catch (e) {
        print("Error while sending image: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreenForUser(uid: widget.otherUserId),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundImage: widget.otherUserProfilePic.isNotEmpty
                    ? NetworkImage(widget.otherUserProfilePic)
                    : const AssetImage('assets/default-profile.jpg') as ImageProvider,
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatrooms')
                  .doc(widget.chatroomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    bool isMe = message['senderId'] == currentUser?.uid;
                    var timestamp = message['timestamp'] as Timestamp?;
                    var timeString = timestamp != null
                        ? DateFormat('HH:mm').format(timestamp.toDate())
                        : '';

                    String messageText = message['message'];
                    bool isImage = messageText.startsWith("http") && messageText.contains("cloudinary");

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isImage)
                                  Image.network(messageText) // Display image
                                else
                                  Text(
                                    messageText,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  timeString,
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.black.withOpacity(0.5),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
