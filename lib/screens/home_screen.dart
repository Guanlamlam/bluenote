import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/guanlam/post_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
  late FirebaseService firebaseService;
  late User? user;
  Map<String, dynamic> userData = {};
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;

  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    firebaseService = FirebaseService();
    user = firebaseService.getCurrentUser();
    if (user != null) {
      _loadInitialData(user!.uid);
    }
  }

  Future<void> _loadInitialData(String uid) async {
    final fetchedUserData = await firebaseService.getUserData(uid);
    final fetchedPosts = await firebaseService.getPosts();
    setState(() {
      userData = fetchedUserData;
      posts = fetchedPosts;
      isLoading = false;
    });
  }

  Future<void> _refreshPosts() async {
    if (user == null) return;
    final fetchedPosts = await firebaseService.getPosts();
    setState(() {
      posts = fetchedPosts;
    });
  }

  List<Map<String, dynamic>> _filterPostsByCategory(
    List<Map<String, dynamic>> allPosts,
  ) {
    if (selectedCategory == 'All') return allPosts;
    return allPosts
        .where((post) => post['category'] == selectedCategory)
        .toList();
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5, // number of skeletons to show
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),

                  // Title placeholder
                  Container(height: 14, width: 200, color: Colors.white),
                  const SizedBox(height: 8),

                  // Subtitle/content line
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.6,
                    color: Colors.white,
                  ),
                ],
              ),
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
      body:
          user == null
              ? Center(child: Text("No user is currently signed in."))
              : isLoading
              ? Center(child: _buildSkeletonLoader())
              : RefreshIndicator(
                onRefresh: _refreshPosts,
                child: CustomScrollView(
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
                          ],
                        ),
                      ),
                    ),

                    // ListView with posts
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = filteredPosts[index];
                        return PostWidget(
                          postId: post['id'],
                          author: post['author'],
                          title: post['title'] ?? 'Untitled Post',
                          content: post['content'] ?? 'No description',
                          imageUrls: List<String>.from(post['image'] ?? []),
                          initialLikes: post['likes'] ?? 0,
                          dateTime: post['dateTime'],
                          firebaseService: firebaseService,
                          user: user!,
                        );
                      }, childCount: filteredPosts.length),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(height: 48),
                          Center(child: Text('- No more -')),
                          SizedBox(height: 48),
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
