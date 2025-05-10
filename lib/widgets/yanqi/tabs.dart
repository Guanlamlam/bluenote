import 'package:flutter/material.dart';
import 'package:bluenote/providers/post_provider.dart';
import 'package:bluenote/widgets/yanqi/auth/own_post_widget.dart';
import 'package:bluenote/widgets/yanqi/lost_found_tab.dart';
import 'package:provider/provider.dart';

class Tabs extends StatefulWidget {
  final String selectedTab;
  final String userId;  // User ID of the user whose profile is being viewed

  const Tabs({super.key, required this.selectedTab, required this.userId});

  @override
  _TabsState createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fetch user data asynchronously in initState()
  Future<void> _loadData() async {
    fetchUserPosts();
    fetchLikedPosts();
  }

  // Fetch posts by the specified user (Post tab)
  Future<void> fetchUserPosts() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    postProvider.clearUserPosts(); // Clear previous data
    await postProvider.fetchUserOwnPosts(widget.userId);  // Pass the user ID to fetch posts for that user
    setState(() {
      isLoading = false;
    });
  }

  // Fetch liked posts by the specified user (Liked tab)
  Future<void> fetchLikedPosts() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    postProvider.clearLikedPosts(); // Clear previous data
    await postProvider.fetchUserLikePosts(widget.userId);  // Pass the user ID to fetch liked posts for that user
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final userPosts = postProvider.userPosts;
    final likedPosts = postProvider.userLikePosts;

    return DefaultTabController(
      length: 3,  // We have 3 tabs: Post, Liked, Lost Found
      child: Column(
        children: [
          // Tab Bar
          TabBar(
            tabs: const [
              Tab(text: 'Post'),
              Tab(text: 'Liked'),
              Tab(text: 'Lost Found'), // Lost & Found tab
            ],
          ),
          Container(
            height: 600, // Adjust height as needed
            child: TabBarView(
              children: [
                // Post Tab: Display the user's posts
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: userPosts.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    var post = userPosts[index];
                    return OwnPostWidget(post: post);  // Display the post
                  },
                ),

                // Liked Tab: Display liked posts by the user
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: likedPosts.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    var post = likedPosts[index];
                    return OwnPostWidget(post: post);  // Display the liked post
                  },
                ),

                // Lost Found Tab: Display Lost & Found data
                LostFoundTab(),  // Assuming you have a widget to display Lost & Found items
              ],
            ),
          ),
        ],
      ),
    );
  }
}
