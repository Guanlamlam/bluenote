import 'package:bluenote/service/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class PostModel {
  final String postId;
  final String author;
  final String authorUid;
  final String title;
  final String content;
  final List<String> imageUrls;
  final DateTime dateTime;
  final int likes;
  final String category;

  PostModel({
    required this.postId,
    required this.author,
    required this.authorUid,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.dateTime,
    required this.likes,
    required this.category,
  });

  // From a map
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      postId: map['postId'] ?? '',
      author: map['author'] ?? 'Unknown',
      authorUid: map['authorUid'] ?? '',
      title: map['title'] ?? 'Untitled Post',
      content: map['content'] ?? map['description'] ?? 'No description',
      imageUrls: (map['image'] as List?)?.whereType<String>().toList() ?? [],
      dateTime: (map['dateTime'] is Timestamp)
          ? (map['dateTime'] as Timestamp).toDate()
          : (map['dateTime'] ?? DateTime.now()),
      likes: map['likes'] ?? 0,
      category: map['category'] ?? '',
    );
  }

  // Convert back to map if needed
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'author': author,
      'authorUid': authorUid,
      'title': title,
      'content': content,
      'image': imageUrls,
      'dateTime': dateTime,
      'likes': likes,
      'category': category,
    };
  }
}




class SelectedPostProvider extends ChangeNotifier {
  PostModel? _post;
  Map<String, dynamic>? _authorData;

  PostModel? get post => _post;
  Map<String, dynamic>? get authorData => _authorData;

  void setPost(PostModel? post) {
    _post = post;
    notifyListeners();
    if (post != null) {
      _loadAuthorProfile(post.authorUid);
    }
  }

  // Load Author Profile based on the authorUid
  Future<void> _loadAuthorProfile(String authorUid) async {
    _authorData = await FirebaseService.instance.getUserData(authorUid);
    notifyListeners();  // Notify listeners when author data is fetched
  }

  void clearPost() {
    _post = null;
    notifyListeners();
  }
}
