
import 'package:bluenote/providers/post_provider.dart';
import 'package:bluenote/widgets/yanqi/auth/own_post_widget.dart';
import 'package:bluenote/widgets/yanqi/lost_found_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bluenote/widgets/yanqi/auth/login_form.dart';

class Tabs extends StatefulWidget {
  final String selectedTab;

  const Tabs({super.key, required this.selectedTab});

  @override
  _TabsState createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  bool isLoading = true;

  String? userId;
  String? userName;
  String? profilePicture;


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
    // Retrieve cached user info
    final userData = await getCachedUserData();
    userId = userData['userId'];
    userName = userData['username'];
    profilePicture = userData['profilePictureUrl'];

    fetchUserPosts();
    fetchLikedPosts();
  }

  // Fetch posts by the logged-in user (Post tab)
  Future<void> fetchUserPosts() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    postProvider.clearUserPosts(); // Clear previous data
    await postProvider.fetchUserOwnPosts(userId!);
    setState(() {
      isLoading = false;
    });
  }

  // Fetch liked posts by the user (Liked tab)
  Future<void> fetchLikedPosts() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    postProvider.clearLikedPosts(); // Clear previous data
    await postProvider.fetchUserLikePosts(userId!);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final postProvider = Provider.of<PostProvider>(context);
    final userPosts = postProvider.userPosts;
    final likedPosts = postProvider.userLikePosts;

    print(likedPosts);
    print(userPosts);
    return DefaultTabController(
        length: 3,
        child: Column(
            children: [
              // Tab Bar
              TabBar(
                tabs: const [
                  Tab(text: 'Post'),
                  Tab(text: 'Liked'),
                  Tab(text: 'Lost Found'), // New tab
                ],
              ),
              Container(
                height: 600, // Adjust height as needed
                child: TabBarView(
                  children: [
                    // Post Tab: Display user's posts

                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : postProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      itemCount: userPosts.length,
                      padding: const EdgeInsets.all(8.0), // Add padding if necessary
                      itemBuilder: (context, index) {
                        var post = userPosts[index];
                        return OwnPostWidget(post: post);
                      },
                    ),


                    // Liked Tab: Display liked posts
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : postProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      itemCount: likedPosts.length,
                      padding: const EdgeInsets.all(8.0), // Add padding if necessary
                      itemBuilder: (context, index) {
                        var post = likedPosts[index];
                        return OwnPostWidget(post: post);
                      },
                    ),
                    LostFoundTab(), // New content
                  ],
                ),
              ),
            ],
          ),
        );
    }
}