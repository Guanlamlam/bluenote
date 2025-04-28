import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class FirebaseService {
  // Singleton instance
  static final FirebaseService instance = FirebaseService._();

  // Private constructor
  FirebaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

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

  Future<List<Map<String, dynamic>>> getPosts({DocumentSnapshot? lastDoc, int limit = 5}) async {
    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('dateTime', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['snapshot'] = doc; // Store snapshot for pagination
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching paginated posts: $e");
      return [];
    }
  }



  Future<void> uploadPost({
    required String title,
    String? content,
    required String category,
    List<String>? imageUrls,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

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
      'image': imageUrls,
    });
  }

  Future<void> deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }


  Future<String?> uploadToCloudinary(File imageFile) async {
    final String cloudinaryUrl = 'https://api.cloudinary.com/v1_1/diobtnw7s/image/upload';
    final String uploadPreset = 'bluenote';

    try {
      final mimeType = lookupMimeType(imageFile.path);
      final mimeSplit = mimeType?.split('/');

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: mimeSplit != null
            ? MediaType(mimeSplit[0], mimeSplit[1])
            : MediaType('image', 'jpeg'),
      ));
      request.fields['upload_preset'] = uploadPreset;

      var response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(resBody);
        return data['secure_url'];
      } else {
        print("❌ Upload failed: $resBody");
        return null;
      }
    } catch (e) {
      print("❌ Exception: $e");
      return null;
    }
  }

  Future<void> toggleLike(String postId, String uid) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);

    final doc = await likeRef.get();

    if (doc.exists) {
      await likeRef.delete();
      await postRef.update({'likes': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      await postRef.update({'likes': FieldValue.increment(1)});
    }
  }

  Future<bool> hasUserLiked(String postId, String uid) async {
    final doc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .get();
    return doc.exists;
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

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

  Future<void> deleteComment(BuildContext context, String postId, String commentId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Comment deleted successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete comment: $e")));
    }
  }

  Future<int> getCommentCount(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      return querySnapshot.size;
    } catch (e) {
      return 0;
    }
  }

  Future<void> toggleLikeComment(String postId, String commentId, String uid) async {
    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    final likeRef = commentRef.collection('likes').doc(uid);

    final doc = await likeRef.get();

    if (doc.exists) {
      await likeRef.delete();
      await commentRef.update({'likes': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      await commentRef.update({'likes': FieldValue.increment(1)});
    }
  }

  Future<bool> checkIfLiked(String postId, String commentId, String uid) async {
    final likeDoc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(uid)
        .get();

    return likeDoc.exists;
  }


  Future<void> addNotification({
    required String targetUid,
    required String username,
    required String message,
    String? profileImage,
    String? postId,
    String? postThumbnail,
  }) async {
    try {
      await _firestore.collection('users').doc(targetUid).collection('notifications').add({
        'username': username,
        'message': message,
        'profileImage': profileImage ?? '',
        'postId': postId ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'postThumbnail': postThumbnail,
        'viewed': false,
      });
    } catch (e) {
      debugPrint('Failed to add notification: $e'); // use debugPrint for better Flutter practice
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
      return [];
    }
  }

  Future<void> deleteNotification(String uid, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Failed to delete notification: $e');
    }
  }

  Future<void> markNotificationAsViewed(String uid, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'viewed': true});
    } catch (e) {
      debugPrint('❌ Failed to mark notification as viewed: $e');
    }
  }

  Stream<int> getUnreadNotificationCountStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('viewed', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }







}
