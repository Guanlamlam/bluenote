import 'package:bluenote/providers/post_provider.dart';
import 'package:bluenote/screens/auth/post/browsing_history_screen.dart';
import 'package:bluenote/widgets/guanlam/models/post_model.dart';
import 'package:bluenote/widgets/guanlam/post_widget.dart';
import 'package:bluenote/widgets/yanqi/auth/login_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:waterfall_flow/waterfall_flow.dart';
import '../widgets/guanlam/category_button.dart';
import '../widgets/guanlam/custom_app_bar.dart';
import '../widgets/guanlam/bottom_nav_bar.dart';
import 'post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userId;
  String? userName;
  String? profilePicture;

  bool isLoading = true;
  String selectedCategory = 'All';

  ///!!!
  bool isFetchingMore = false;
  bool hasMore = true;
  DocumentSnapshot? lastDoc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadInitialData();
    requestPermission();

    _scrollController.addListener(() {
      // Check if scroll position is near the end of the list (for infinite scroll)
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 && !isFetchingMore && hasMore) {
        setState(() {
          isFetchingMore = true; // Show the loader
        });

        // Fetch more posts asynchronously
        Provider.of<PostProvider>(context, listen: false).fetchMorePosts();

        setState(() {
          isFetchingMore = false; // Hide the loader once fetching is done
        });

      }
    });
  }

  @override
  void dispose() {

    super.dispose();
  }



  // Fetch user data asynchronously in initState()
  Future<void> _loadUserData() async {
    // Retrieve cached user info
    final userData = await getCachedUserData();
    userId = userData['userId'];
    userName = userData['username'];
    profilePicture = userData['profilePictureUrl'];
  }

  Future<void> _loadInitialData() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    await postProvider.fetchMorePosts(); // Fetch posts from the provider

    setState(() {
      isLoading = false;
    });
  }




  Future<void> requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _refreshPosts() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    await postProvider.fetchMorePosts();
  }

  List<PostModel> _filterPostsByCategory(
    List<PostModel> allPosts, // Pass a list of posts instead of a single post
  ) {
    if (selectedCategory == 'All') return allPosts;

    return allPosts.where((post) => post.category == selectedCategory).toList();
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        // Set grid delegate with 2 columns
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two columns
          crossAxisSpacing: 2.0, // Horizontal spacing between columns
          mainAxisSpacing: 2.0, // Vertical spacing between rows
          childAspectRatio:
              0.7, // Adjust to get the desired height-to-width ratio
        ),
        itemCount: 6, // Number of skeletons to show
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final posts = postProvider.posts;
    final filteredPosts = _filterPostsByCategory(posts);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(),
      body:
          userId == null
              // ? Center(child: Text("No user is currently signed in."))
              // : isLoading
              ? Center(child: _buildSkeletonLoader())
              : RefreshIndicator(
                onRefresh: _refreshPosts,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Category buttons row
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        margin: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CategoryButton(
                              text: 'All',
                              isSelected: selectedCategory == 'All',
                              onTap: () {
                                setState(() {
                                  selectedCategory = 'All';
                                });
                              },
                            ),
                            SizedBox(width: 12),
                            CategoryButton(
                              text: 'Events',
                              isSelected: selectedCategory == 'Events',
                              onTap: () {
                                setState(() {
                                  selectedCategory = 'Events';
                                });
                              },
                            ),
                            SizedBox(width: 12),
                            CategoryButton(
                              text: 'Q&A',
                              isSelected: selectedCategory == 'Q&A',
                              onTap: () {
                                setState(() {
                                  selectedCategory = 'Q&A';
                                });
                              },
                            ),
                            // SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => BrowsingHistoryScreen(),
                                  ),
                                );
                              },
                              child: Text('History'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content water fall layout
                    SliverWaterfallFlow(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = filteredPosts[index];

                        return PostWidget(post: post);
                      }, childCount: filteredPosts.length),
                      gridDelegate:
                          SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                          ),
                    ),

                    // Footer with loading indicator or no more posts message
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          if (isFetchingMore)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 84),
                              child: CircularProgressIndicator(),
                            )
                          else if (!postProvider.hasMore)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 84),
                              child: Text('- No more -'),
                            ),


                        ],
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostScreen()),
          );
        },
        shape: CircleBorder(),
        child: Icon(Icons.add, color: Colors.white, size: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(),
    );
  }
}


