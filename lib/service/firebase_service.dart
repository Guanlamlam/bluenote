import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }



  // Fetch user document data from Firestore
  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('posts').orderBy('dateTime', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the post data (field)
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> uploadPost({
    required String title,
    String? content,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Fetch display name from Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final authorName = userDoc.data()?['username'] ?? 'Anonymous';

    await _firestore.collection('posts').add({
      'title': title,
      'content': content,
      'category': category,
      'author': authorName,
      'authorUid': user.uid,
      'dateTime': Timestamp.now(),
      'likes': 0,
      'image':[""],
    });
  }




  Future<void> toggleLike(String postId, String uid) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);

    final doc = await likeRef.get();

    if (doc.exists) {
      // 👎 Unlike
      await likeRef.delete();
      await postRef.update({'likes': FieldValue.increment(-1)});
    } else {
      // 👍 Like
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      await postRef.update({'likes': FieldValue.increment(1)});
    }
  }

  Future<bool> hasUserLiked(String postId, String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .get();
    return doc.exists;
  }



}
