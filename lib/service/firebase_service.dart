import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  //Comment read
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('likes', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Optional: include comment ID
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }


  //Comment add
  Future<void> addComment({
    required String postId,
    required String userId,
    required String username,
    required String comment,
  }) async {
    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc();

    await commentRef.set({
      'userId': userId,
      'username': username,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
    });
  }

  //Comment delete
  Future<void> deleteComment(BuildContext context, String postId, String commentId) async {
    try {
      // Delete the comment from the comments sub-collection under the post
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Optionally, you can refresh the UI after deletion
      // _loadComments(); // if you're using this method for reloading comments

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Comment deleted successfully"))
      );
    } catch (e) {
      // Show error message in case of failure
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete comment: $e"))
      );
    }
  }

  Future<void> toggleLikeComment(String postId,String commentId,String uid) async {
    final postCommentRef = FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').doc(commentId);
    final likeRef = postCommentRef.collection('likes').doc(uid);

    final doc = await likeRef.get();

    //actually this is wrong if the user has been liked it and click again should be delete , and like -1, as other will also like
    if (doc.exists) {
      // 👎 Unlike
      await likeRef.delete();
      await postCommentRef.update({'likes': FieldValue.increment(-1)});
    } else {
      // 👍 Like
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      await postCommentRef.update({'likes': FieldValue.increment(1)});
    }
  }

  Future<bool> checkIfLiked(String postId, String commentId, String uid) async {
    final likeDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(uid)
        .get();

    return likeDoc.exists;
  }






}
