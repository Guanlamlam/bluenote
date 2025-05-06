import 'dart:convert';

class BrowsingHistoryModel {
  final int? id;
  final String postId;
  final String title;
  final String content;
  final String author;
  final String authorProfileURL;
  final List<String> imagesURL;
  final DateTime viewedAt;

  BrowsingHistoryModel({
    this.id,
    required this.postId,
    required this.title,
    required this.content,
    required this.author,
    required this.authorProfileURL,
    required this.imagesURL,
    required this.viewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'title': title,
      'content': content,
      'author': author,
      'authorProfileURL': authorProfileURL,
      'imagesURL': jsonEncode(imagesURL), // Encode list
      'viewedAt': viewedAt.toIso8601String(),
    };
  }

  factory BrowsingHistoryModel.fromMap(Map<String, dynamic> map) {
    return BrowsingHistoryModel(
      id: map['id'],
      postId: map['postId'],
      title: map['title'],
      content: map['content'],
      author: map['author'],
      authorProfileURL: map['authorProfileURL'],
      imagesURL: List<String>.from(jsonDecode(map['imagesURL'])),
      viewedAt: DateTime.parse(map['viewedAt']),
    );
  }
}
