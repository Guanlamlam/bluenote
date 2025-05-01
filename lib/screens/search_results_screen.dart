import 'package:bluenote/providers/selected_post_provider.dart';
import 'package:bluenote/service/firebase_service.dart';
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
  List<Map<String, dynamic>> filteredPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    final rawResults = await FirebaseService.instance.searchPosts(widget.query);

    // Optionally: get author data for each post
    final resultsWithAuthor = await Future.wait(rawResults.map((post) async {
      final authorData = await FirebaseService.instance.getUserData(post['authorUid']);
      return {
        'postModel': PostModel.fromMap(post),
        'authorData': authorData,
      };
    }));

    setState(() {
      filteredPosts = resultsWithAuthor;
      isLoading = false;
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
                    postModel: post['postModel'],
                    authorData: post['authorData'],
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
