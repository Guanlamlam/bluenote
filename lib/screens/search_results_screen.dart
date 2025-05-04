
import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/guanlam/models/post_model.dart';
import 'package:bluenote/widgets/guanlam/post_widget.dart';
import 'package:flutter/material.dart';
import 'package:waterfall_flow/waterfall_flow.dart';


class SearchResultsScreen extends StatefulWidget {
  final String query;

  SearchResultsScreen({required this.query});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<PostModel> filteredPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true; // Start loading
    });

    // Get search results from Firebase
    final rawResults = await FirebaseService.instance.searchPosts(widget.query);

    // Map the raw results to a list of PostModel objects, including author data
    final posts = await Future.wait(rawResults.map((data) async {
      final post = PostModel.fromMap(data);

      // Fetch the author's data
      final authorData = await FirebaseService.instance.getUserData(post.authorUid);

      // Add the author data to the post
      post.authorData = authorData;

      return post;
    }));

    setState(() {
      filteredPosts = posts; // Set filteredPosts to the list of PostModel objects with author data
      isLoading = false; // End loading
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search: ${widget.query}',
          style: TextStyle(fontSize: 18), // smaller font
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: SliverWaterfallFlow(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final post = filteredPosts[index];
                  return PostWidget(
                    post: post,
                  );
                },
                childCount: filteredPosts.length,
              ),
              gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
