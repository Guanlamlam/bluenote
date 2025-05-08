import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the other participant in a conversation
  Future<String> getOtherParticipant(String conversationId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not logged in');

    try {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.isEmpty) {
        throw Exception('No participants found in the conversation');
      }
      return participants.firstWhere((id) => id != currentUserId);
    } catch (e) {
      throw Exception('Failed to get other participant: $e');
    }
  }

  // Get participant details
  Future<Map<String, dynamic>> getParticipantDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to fetch participant details: $e');
    }
  }

  // Send a message function
  Future<void> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    try {
      // Validate inputs
      if (receiverId.isEmpty || message.isEmpty) {
        throw ArgumentError("Receiver ID and message cannot be empty");
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      final senderId = currentUser.uid;
      final conversationId = _generateConversationId(senderId, receiverId);

      if (conversationId.isEmpty) {
        throw ArgumentError("Conversation ID cannot be empty");
      }

      final conversationRef = _firestore.collection('conversations').doc(conversationId);

      // Create or update conversation
      await _ensureConversationExists(conversationRef, senderId, receiverId);

      // Add message to subcollection
      await _addMessageToConversation(conversationRef, senderId, message);

      print("Message sent successfully to conversation $conversationId");
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }

  // Helper method to generate conversation ID
  String _generateConversationId(String user1, String user2) {
    final users = [user1, user2]..sort();
    return users.join("_");
  }

  // Helper method to ensure conversation exists
  Future<void> _ensureConversationExists(
      DocumentReference conversationRef,
      String senderId,
      String receiverId,
      ) async {
    final snapshot = await conversationRef.get();

    if (!snapshot.exists) {
      await conversationRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': '',
        'lastMessageTime': Timestamp.now(),
        'userIds': [senderId, receiverId],
      });
      print('Conversation created: $conversationRef');
    } else {
      print('Conversation already exists');
    }
  }

  // Helper method to add message to conversation
  Future<void> _addMessageToConversation(
      DocumentReference conversationRef,
      String senderId,
      String message,
      ) async {
    // Add message to messages subcollection
    await conversationRef.collection('messages').add({
      'senderId': senderId,
      'message': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
    });

    // Update conversation with latest message
    await conversationRef.update({
      'lastMessage': message,
      'lastMessageTime': Timestamp.now(),
    });
    print("Message added to conversation");
  }

  // Fetch all conversations for the logged-in user
  Stream<QuerySnapshot> getConversations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not authenticated");
    }

    return _firestore.collection('conversations')
        .where('userIds', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Fetch messages for a specific conversation with validation
  Stream<QuerySnapshot> getMessages(String conversationId) {
    if (conversationId.isEmpty) {
      throw ArgumentError("Conversation ID cannot be empty");
    }

    return _firestore.collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }
}
