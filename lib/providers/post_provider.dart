import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/guanlam/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  PostModel? _selectedPost;
  bool _isLoading = false;

  List<PostModel> _userPosts = [];
  List<PostModel> _userLikePosts = [];

  List<PostModel> get posts => _posts;
  PostModel? get selectedPost => _selectedPost;
  bool get isLoading => _isLoading;

  List<PostModel> get userPosts => _userPosts;
  List<PostModel> get userLikePosts => _userLikePosts;


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




  // Fetch user own posts and their author data (YQ)
  Future<void> fetchUserOwnPosts(String userId) async {
    if (userId.isEmpty) {
      return; // Exit early if userId is invalid
    }

    try {
      final postsData = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorUid', isEqualTo: userId)
          .get();

      if (postsData.docs.isEmpty) {
        print('No posts found for user $userId');
        return;  // Return if no posts found
      }

      // Iterate through the documents to convert them to PostModel
      for (var doc in postsData.docs) {
        final data = doc.data();
        data['postId'] = doc.id; // Add postId to the data
        final post = PostModel.fromMap(data);  // Use data to create PostModel

        // Fetch author data
        post.authorData = await FirebaseService.instance.getUserData(post.authorUid);
        _userPosts.add(post);  // Add to the list of posts
      }

      notifyListeners();  // Notify listeners after data is fetched
    } catch (e) {
      print("Error fetching posts: $e");
    }
  }

  Future<void> fetchUserLikePosts(String userId) async {
    if (userId.isEmpty) {
      return; // Exit early if userId is invalid
    }

    try {
      // Fetch all posts
      final postsData = await FirebaseFirestore.instance
          .collection('posts')
          .get();

      if (postsData.docs.isEmpty) {
        print('No posts found');
        return;
      }

      // Iterate through the posts and check if the user liked them
      for (var doc in postsData.docs) {
        final postId = doc.id;

        // Query the likes subcollection for the specific post to check if the user has liked it
        final likeDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('likes')
            .doc(userId) // Check if the user has liked this post by userId
            .get();

        // If the document exists, it means the user liked the post
        if (likeDoc.exists) {
          final data = doc.data();
          data['postId'] = postId; // Add postId to the data

          // Convert to PostModel
          final post = PostModel.fromMap(data);

          // Fetch author data
          post.authorData = await FirebaseService.instance.getUserData(post.authorUid);
          _userLikePosts.add(post);  // Add to the list of liked posts
        }
      }

      notifyListeners();  // Notify listeners after data is fetched
    } catch (e) {
      print("Error fetching liked posts: $e");
    }
  }
  // Method to clear the user posts list
  void clearUserPosts() {
    _userPosts.clear();
    notifyListeners(); // Notify listeners after clearing
  }

  // Method to clear the liked posts list
  void clearLikedPosts() {
    _userLikePosts.clear();
    notifyListeners(); // Notify listeners after clearing
  }

  Future<void> deleteOwnPost(String postId) async {
    try {
      await FirebaseService.instance.deletePost(postId);
      _userPosts.removeWhere((post) => post.postId == postId);
      if (_selectedPost?.postId == postId) {
        _selectedPost = null;
      }
      notifyListeners();
    } catch (e) {
      print("Error deleting post: $e");
    }
  }






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

