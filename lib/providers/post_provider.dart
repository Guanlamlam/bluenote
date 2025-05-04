import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/guanlam/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  PostModel? _selectedPost;
  bool _isLoading = false;

  List<PostModel> get posts => _posts;
  PostModel? get selectedPost => _selectedPost;
  bool get isLoading => _isLoading;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  Future<void> fetchMorePosts() async {
    if (!_hasMore || _isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final postsData = await FirebaseService.instance.getPosts(lastDoc: _lastDoc);
      if (postsData.isEmpty) {
        _hasMore = false;
      } else {
        for (var postData in postsData) {
          final post = PostModel.fromMap(postData, snapshot: postData['snapshot']);
          post.authorData = await FirebaseService.instance.getUserData(post.authorUid);
          _posts.add(post);
        }
        _lastDoc = postsData.last['snapshot'];
      }
    } catch (e) {
      print("Error fetching more posts: $e");
    }

    _isLoading = false;
    notifyListeners();
  }




  // Fetch all posts and their author data
  // Future<void> fetchPosts() async {
  //   try {
  //     final postsData = await FirebaseService.instance.getPosts();
  //     _posts = await Future.wait(postsData.map((postData) async {
  //       final post = PostModel.fromMap(postData);
  //       final authorData = await FirebaseService.instance.getUserData(post.authorUid);
  //       post.authorData = authorData;
  //       return post;
  //     }));
  //     notifyListeners();
  //   } catch (e) {
  //     print("Error fetching posts: $e");
  //   }
  // }

  // Future<List<PostModel>> fetchPosts({DocumentSnapshot? lastDoc, int limit = 5}) async {
  //   try {
  //     final postsData = await FirebaseService.instance.getPosts(lastDoc: lastDoc, limit: limit);
  //
  //     final fetchedPosts = await Future.wait(postsData.map((postData) async {
  //       final post = PostModel.fromMap(postData);
  //       final authorData = await FirebaseService.instance.getUserData(post.authorUid);
  //       post.authorData = authorData;
  //       return post;
  //     }));
  //
  //     _posts.addAll(fetchedPosts);
  //     notifyListeners();
  //
  //     // Return the last document fetched for pagination
  //     return fetchedPosts;
  //   } catch (e) {
  //     print("Error fetching posts: $e");
  //     return [];
  //   }
  // }


  // Set selected post and fetch its author profile
  Future<void> setSelectedPost(PostModel post) async {
    _isLoading = true;
    notifyListeners();  // Notify listeners that loading has started

    _selectedPost = post;
    try {
      final authorData = await FirebaseService.instance.getUserData(post.authorUid);
      post.authorData = authorData;
    } catch (e) {
      print("Error loading author data: $e");
    }

    _isLoading = false;
    notifyListeners();  // Notify listeners that loading has finished
  }

  // Add a new post
  // Future<void> addPost(PostModel newPost) async {
  //   try {
  //     // Add to local list after successful addition
  //     _posts.add(newPost);
  //     notifyListeners();
  //   } catch (e) {
  //     print("Error add post: $e");
  //   }
  // }
  Future<void> addPost(PostModel newPost) async {
    try {
      // Call FirebaseService to add the post to Firestore
      _posts.add(newPost);

      // Add the new post locally after successful addition
      _posts.insert(0, newPost);  // You might want to add it at the top of the list
      notifyListeners();
    } catch (e) {
      print("Error adding post: $e");
    }
  }


  // Remove a post locally and from the database
  Future<void> deletePost(String postId) async {
    try {
      await FirebaseService.instance.deletePost(postId);
      _posts.removeWhere((post) => post.postId == postId);
      if (_selectedPost?.postId == postId) {
        _selectedPost = null;
      }
      notifyListeners();
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  // Update a post
  void updatePost(PostModel updatedPost) {
    // Find the index of the post to update
    final index = _posts.indexWhere((post) => post.postId == updatedPost.postId);
    if (index != -1) {
      // Replace the old post with the updated post
      _posts[index] = updatedPost;
      notifyListeners(); // Notify listeners to update UI
    }
  }
}

