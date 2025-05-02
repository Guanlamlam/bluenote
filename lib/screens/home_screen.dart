import 'package:bluenote/providers/selected_post_provider.dart';
import 'package:bluenote/screens/auth/post/browsing_history_screen.dart';
import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/guanlam/post_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:waterfall_flow/waterfall_flow.dart';
import '../widgets/guanlam/category_button.dart';
import '../widgets/guanlam/custom_app_bar.dart';
import '../widgets/guanlam/bottom_nav_bar.dart';
import 'post_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late User? user;

  List<Map<String, dynamic>> posts = [];
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
    user = FirebaseService.instance.getCurrentUser();
    if (user != null) {
      _loadInitialData();
    }
    requestPermission();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        _loadMorePosts();
      }
    });


  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final fetchedPosts = await FirebaseService.instance.getPosts();
    final List<Map<String, dynamic>> postsWithAuthor = [];

    for (var post in fetchedPosts) {
      final postModel = PostModel.fromMap(post);
      final authorData = await FirebaseService.instance.getUserData(postModel.authorUid);
      postsWithAuthor.add({
        'postModel': postModel,
        'authorData': authorData,

      });
    }

    if (fetchedPosts.isNotEmpty) {
      lastDoc = fetchedPosts.last['snapshot'];
    }

    setState(() {
      posts = postsWithAuthor;
      isLoading = false;
    });

  }


  Future<void> _loadMorePosts() async {
    if (isFetchingMore || !hasMore) return;

    setState(() => isFetchingMore = true);

    final fetchedPosts = await FirebaseService.instance.getPosts(lastDoc: lastDoc);
    final List<Map<String, dynamic>> newPostsWithAuthor = [];

    for (var post in fetchedPosts) {
      final postModel = PostModel.fromMap(post);
      final authorData = await FirebaseService.instance.getUserData(postModel.authorUid);
      newPostsWithAuthor.add({
        'postModel': postModel,
        'authorData': authorData,
      });
    }

    if (fetchedPosts.isNotEmpty) {
      lastDoc = fetchedPosts.last['snapshot'];
      setState(() {
        posts.addAll(newPostsWithAuthor);
      });
    } else {
      setState(() => hasMore = false);
    }

    setState(() => isFetchingMore = false);
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
    if (user == null) return;

    final fetchedPosts = await FirebaseService.instance.getPosts();
    final List<Map<String, dynamic>> postsWithAuthor = [];

    for (var post in fetchedPosts) {
      final postModel = PostModel.fromMap(post);
      final authorData = await FirebaseService.instance.getUserData(postModel.authorUid);
      postsWithAuthor.add({
        'postModel': postModel,
        'authorData': authorData,
      });
    }

    setState(() {
      posts = postsWithAuthor;
    });
  }


  List<Map<String, dynamic>> _filterPostsByCategory(
    List<Map<String, dynamic>> allPosts,
  ) {
    if (selectedCategory == 'All') return allPosts;
    return allPosts
        .where((post) =>
    (post['postModel'] as PostModel).category == selectedCategory)
        .toList();

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
          childAspectRatio: 0.7, // Adjust to get the desired height-to-width ratio
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
    final filteredPosts = _filterPostsByCategory(posts);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: CustomAppBar(),
        body: user == null
            ? Center(child: Text("No user is currently signed in."))
            : isLoading
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
                      TextButton(onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BrowsingHistoryScreen()),
                        );
                      }, child: Text('History'))
                    ],
                  ),
                ),
              ),

              // Content water fall layout
              SliverWaterfallFlow(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final post = filteredPosts[index];

                    final postModel = post['postModel'] as PostModel;
                    final authorData = post['authorData'] as Map<String, dynamic>;

                    return PostWidget(
                      postModel: postModel,
                      authorData: authorData,
                    );


                      },
                  childCount: filteredPosts.length,
                ),
                gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
              ),



              // Footer with loading indicator or no more posts message
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (isFetchingMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      )
                    else if (!hasMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
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
