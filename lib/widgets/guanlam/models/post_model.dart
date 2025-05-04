import 'package:cloud_firestore/cloud_firestore.dart';

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
  Map<String, dynamic>? authorData;  // Add this field for author data
  DocumentSnapshot? snapshot;

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
    this.authorData,  // Optional author data
    this.snapshot,
  });

  // From a map
  factory PostModel.fromMap(Map<String, dynamic> map, {DocumentSnapshot? snapshot}) {
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
      authorData: map['authorData'], // Optional author data
      snapshot: snapshot,
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
      'authorData': authorData, // Optional author data
    };
  }
}