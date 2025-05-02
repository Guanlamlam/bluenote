import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluenote/widgets/guanlam/database/browsing_history_database.dart';
import 'package:bluenote/widgets/guanlam/image_carousel.dart';
import 'package:bluenote/widgets/guanlam/models/browsing_history_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:waterfall_flow/waterfall_flow.dart';


class BrowsingHistoryScreen extends StatefulWidget {
  const BrowsingHistoryScreen({super.key});

  @override
  _BrowsingHistoryScreenState createState() => _BrowsingHistoryScreenState();
}

class _BrowsingHistoryScreenState extends State<BrowsingHistoryScreen> {
  late Future<List<BrowsingHistoryModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = BrowsingHistoryDatabase.instance.getAllHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Browsing History", style: TextStyle(
          fontSize: 18,
        ),),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            tooltip: "Clear All",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text("Clear All History?"),
                  content: Text("This action cannot be undone."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: Text("Clear"),
                    ),

                  ],
                ),
              );

              if (confirm == true) {
                await BrowsingHistoryDatabase.instance.deleteAllHistory();
                setState(() {
                  _historyFuture = BrowsingHistoryDatabase.instance.getAllHistory();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Browsing history cleared.")),
                );

              }
            },
          ),
        ],
      ),

      body: FutureBuilder<List<BrowsingHistoryModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final historyList = snapshot.data!;
          if (historyList.isEmpty) return Center(child: Text("No history yet."));

          return CustomScrollView(
            slivers: [
              SliverWaterfallFlow(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final history = historyList[index];

                    return GestureDetector(
                      onTap: () {
                        // Navigate to BrowsingHistoryDetailScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrowsingHistoryDetailScreen(
                              history: history, // Pass the history item
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Section - Dynamic height based on image size
                            history.imagesURL[0].isNotEmpty
                                ? Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                maxHeight: 280, // Set the maximum height
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: history.imagesURL[0],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(color: Colors.white),
                                      ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                            )
                                : Container(),
                            // Text Content Section - Dynamically adjust based on content
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AutoSizeText(
                                    history.title,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    minFontSize: 12,
                                    maxFontSize: 24,
                                  ),
                                ],
                              ),
                            ),

                            // Author and Like Section
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  // Author Info
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.transparent,
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: history.authorProfileURL.isEmpty
                                                ? 'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg'
                                                : history.authorProfileURL,
                                            imageBuilder: (context, imageProvider) =>
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                            placeholder: (context, url) =>
                                            const SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            errorWidget: (context, url, error) =>
                                            const Icon(Icons.error, size: 32),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      AutoSizeText(
                                        history.author,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        minFontSize: 10,
                                        maxFontSize: 12,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: historyList.length,
                ),
                gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // You can adjust this value based on how many columns you want
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}



class BrowsingHistoryDetailScreen extends StatelessWidget {
  final BrowsingHistoryModel history; // Passing the history object

  const BrowsingHistoryDetailScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    history.authorProfileURL.isEmpty
                        ? 'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg'
                        : history.authorProfileURL,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  history.author,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display the detailed content of the browsing history
            // Image carousel
            ImageCarousel(imageUrls: history.imagesURL),
            SizedBox(height: 16),

            // Post Title & Description
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Title of the post
                    Text(
                      history.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),

                    ),

                    SizedBox(height: 6),

                    Text(
                      history.content,
                      style: TextStyle(fontSize: 14, color: Colors.black87),


                    ),
                    SizedBox(height: 18),
                    Text(
                      'View at ${DateFormat('dd-MM-yyyy HH:mm').format(history.viewedAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

