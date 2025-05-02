import 'package:bluenote/providers/selected_post_provider.dart';
import 'package:flutter/material.dart';
import 'package:bluenote/service/firebase_service.dart';


class PostProvider extends ChangeNotifier {
  List<PostModel> _posts = []; // List of posts
  PostModel? _selectedPost;
  Map<String, dynamic>? _authorData;

  List<PostModel> get posts => _posts;
  PostModel? get selectedPost => _selectedPost;
  Map<String, dynamic>? get authorData => _authorData;


  // Fetch all posts (or use FirebaseService)
  Future<void> fetchPosts() async {
    try {
      final postsData = await FirebaseService.instance.getPosts(); // You can modify this to fetch all posts
      _posts = postsData.map((post) => PostModel.fromMap(post)).toList();
      notifyListeners();
    } catch (e) {
      print("Error fetching posts: $e");
    }
  }

  // Set selected post
  void setSelectedPost(PostModel post) {
    _selectedPost = post;
    _loadAuthorProfile(post.authorUid);
    notifyListeners();
  }
  // Load Author Profile based on the authorUid
  Future<void> _loadAuthorProfile(String authorUid) async {
    _authorData = await FirebaseService.instance.getUserData(authorUid);
    notifyListeners();  // Notify listeners when author data is fetched
  }

  // Remove a post locally and from the database
  Future<void> deletePost(String postId) async {
    try {
      // First, remove post from Firebase
      await FirebaseService.instance.deletePost(postId);

      // Remove post from local list
      _posts.removeWhere((post) => post.postId == postId);

      // If the deleted post was selected, reset selected post
      if (_selectedPost?.postId == postId) {
        _selectedPost = null;
      }

      notifyListeners(); // Notify listeners that the state has changed
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

// Optionally, add other actions for creating or updating posts
}
