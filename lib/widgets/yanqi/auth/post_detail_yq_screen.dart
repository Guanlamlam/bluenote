import 'package:bluenote/providers/post_provider.dart';
import 'package:bluenote/screens/post_screen.dart';
import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/service/notification_service.dart';
import 'package:bluenote/widgets/guanlam/database/browsing_history_database.dart';
import 'package:bluenote/widgets/guanlam/image_carousel.dart';
import 'package:bluenote/widgets/guanlam/models/browsing_history_model.dart';
import 'package:bluenote/widgets/guanlam/models/post_model.dart';
import 'package:bluenote/widgets/yanqi/auth/login_form.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'package:timeago/timeago.dart' as timeago;


class PostDetailYqScreen extends StatefulWidget {
  PostDetailYqScreen({super.key});

  @override
  State<PostDetailYqScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailYqScreen> {
  final TextEditingController _commentController = TextEditingController();

  int commentCount = 0; // Track the comment count

  String? userId;
  String? userName;
  String? profilePicture;

  String? postId;



  @override
  void initState() {
    super.initState();
    _loadUserData();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure that the data is available before calling the save function
    final post = Provider.of<PostProvider>(context).selectedPost;


    if (post != null) {
      savePostToHistory(post);
    }
    _fetchCommentCount();
  }

  void savePostToHistory(PostModel post) async {
    final history = BrowsingHistoryModel(
      postId: post.postId,
      title: post.title,
      content: post.content,
      author: post.author,
      authorProfileURL: post.authorData!['profilePictureUrl'],
      imagesURL: post.imageUrls,
      viewedAt: DateTime.now(),
    );

    try {
      await BrowsingHistoryDatabase.instance.insertOrUpdateHistory(history);
      await BrowsingHistoryDatabase.instance.maintainHistoryLimit(6);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save post to history: $e')),
      );
    }

  }




  // Fetch user data asynchronously in initState()
  Future<void> _loadUserData() async {
    // Retrieve cached user info
    final userData = await getCachedUserData();
    userId = userData['userId'];
    userName = userData['username'];
    profilePicture = userData['profilePictureUrl'];
  }

  // Fetch the comment count
  Future<void> _fetchCommentCount() async {
    final post = Provider.of<PostProvider>(context).selectedPost;
    int count = await FirebaseService.instance.getCommentCount(post!.postId);

    if (mounted) {
      setState(() {
        commentCount = count;
      });
    }
  }

  void _showCommentOptions(
      BuildContext context,
      Map<String, dynamic> comment,
      String postId,
      String userId,
      ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ListTile(
                leading: Icon(Icons.copy, color: Colors.black),
                title: Text("Copy"),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: comment['comment'] ?? ''),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Comment copied to clipboard")),
                  );
                },
              ),
            ),
            //If comment is created by yourself, can deleted
            if (comment['userId'] == userId)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: Text("Delete", style: TextStyle(color: Colors.red)),

                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet first
                    _showDeleteConfirmationDialog(
                      context,
                      postId,
                      comment['commentId'],
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context,
      String postId,
      String commentId,
      ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "Delete Comment",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text("Are you sure you want to delete this comment?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Just close
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                FirebaseService.instance.deleteComment(
                  context,
                  postId,
                  commentId,
                );
                Navigator.of(context).pop(); // Close after deletion
                setState(() {
                  commentCount--;
                }); // Refresh if needed
              },
              child: Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showPostOptionsBottomSheet(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.black),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                final selectedPost = Provider.of<PostProvider>(context, listen: false).selectedPost;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostScreen(post: selectedPost),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.redAccent),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeletePostDialog(context, postId);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeletePostDialog(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Post"),
          content: Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseService.instance.deletePost(postId);


                // Pop the current screen and go back to the previous screen
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Pop the post detail screen
                await Provider.of<PostProvider>(context, listen: false).deleteOwnPost(postId);
              },
              child: Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode _unfocusNode = FocusNode();

    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final selectedPost = postProvider.selectedPost;
        if (selectedPost == null) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }


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
                      // radius: 16, //set the size of the avatar
                      backgroundImage: CachedNetworkImageProvider(
                        selectedPost.authorData?['profilePictureUrl']?.isEmpty ?? true
                            ? 'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg'
                            : selectedPost.authorData!['profilePictureUrl'],

                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      selectedPost.author,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ],
                ),
                if (userId == selectedPost.authorUid)
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.black),
                    onPressed:
                        () => _showPostOptionsBottomSheet(
                      context,
                      selectedPost.postId,
                    ),
                  ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image carousel
                ImageCarousel(imageUrls: selectedPost.imageUrls),

                //!!!!!!!!!
                // Post Title & Description
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image.asset('assets/img.png', width: 20, height: 15), // Malaysia Flag
                      //Title of the post
                      Text(
                        selectedPost.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        selectedPost.content,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 18),
                      Text(
                        DateFormat(
                          'dd-MM-yyyy HH:mm ',
                        ).format(selectedPost.dateTime), // Example timestamp
                        // timeago.format(selectedPost.dateTime),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Divider(),
                // Comment Input Field
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  child: Text(
                    '$commentCount comments',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        // radius: 32, //set the size of the avatar
                        backgroundImage: CachedNetworkImageProvider(
                          profilePicture ??
                              'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: "Write comment",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // TODO: Handle comment posting
                          String comment = _commentController.text.trim();
                          if (comment.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please enter a comment')),
                            );
                            return; // exit early
                          }

                          await FirebaseService.instance.addComment(
                            postId: selectedPost.postId,
                            userId: userId ?? '',
                            username: userName ?? '',
                            comment: comment,
                          );

                          // ---
                          // Get the post author's FCM token
                          Map<String, dynamic> authorFCM = await FirebaseService.instance.getUserData(
                            selectedPost.authorUid,
                          );
                          String authorFcmToken = authorFCM['fcmToken'];

                          // Send notification to the post author except the author comment their own posts
                          if (authorFcmToken.isNotEmpty &&
                              userName != null &&
                              userId != selectedPost.authorUid) {
                            NotificationService.sendPushNotification(
                              targetToken: authorFcmToken,
                              title: "$userName",
                              body: "comments your posts \n : $comment",
                            );

                            try {
                              await FirebaseService.instance.addNotification(
                                targetUid: selectedPost.authorUid,
                                username: userName!,
                                message: 'comments your posts \n : $comment',
                                profileImage: profilePicture,
                                postId: selectedPost.postId,
                                postThumbnail: selectedPost.imageUrls[0],
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('Failed to send notification')));
                            }
                          }


                          // ---
                          _commentController.clear(); // Clear the input
                          FocusScope.of(context).requestFocus(_unfocusNode);
                          setState(
                                () {
                              commentCount++;
                            },
                          ); // Rebuild the widget to trigger FutureBuilder to refresh
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF203980),
                        ),
                        child: Text(
                          "Send",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Comments Section with FutureBuilder
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: FirebaseService.instance.getComments(
                    selectedPost.postId,
                  ),
                  builder: (context, snapshot) {

                    if (snapshot.hasError) {
                      return Center(child: Text("Failed to load comments"));
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top:30.0 ,bottom: 50.0),
                        child: Center(child: Text("No comments yet.")),
                      );
                    }

                    // Show comments
                    return Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];

                            return CommentTile(
                              comment: comment,
                              postId: selectedPost.postId,
                              onLongPress:
                                  (selectedComment) => _showCommentOptions(
                                context,
                                selectedComment,
                                selectedPost.postId,
                                userId ?? '',
                              ),
                            );
                          },
                        ),
                        // Add "End" text if comments are present
                        SizedBox(height: 24),
                        Center(child: Text('- End -')),
                        SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CommentTile extends StatefulWidget {
  final Map<String, dynamic> comment;
  final String postId;
  final Function(Map<String, dynamic>) onLongPress;

  const CommentTile({
    required this.comment,
    required this.postId,
    required this.onLongPress,
    super.key,
  });

  @override
  _CommentTileState createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  late int likeCount;

  bool isHighlighted = false;
  bool hasLiked = false;
  double _iconScale = 1.0;

  String? userId;
  String? userName;
  String? profilePicture;

  @override
  void initState() {
    super.initState();
    likeCount = widget.comment['likes'] ?? 0;
    _initState();


  }

  Future<void> _initState() async{
    await _loadUserData();
    await _checkIfLiked();
  }

  // Fetch user data asynchronously in initState()
  Future<void> _loadUserData() async {
    // Retrieve cached user info
    final userData = await getCachedUserData();
    userId = userData['userId'];
    userName = userData['username'];
    profilePicture = userData['profilePictureUrl'];
  }

  Future<void> _checkIfLiked() async {
    final likeDoc = await FirebaseService.instance.checkIfLiked(
      widget.postId,
      widget.comment['commentId'],
      userId!,
    );

    setState(() {
      hasLiked = likeDoc;
    });
  }

  void highlight() {
    setState(() => isHighlighted = true);
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isHighlighted = false);
      }
    });
  }

  Future<void> _toggleLike() async {
    // Bounce animation
    setState(() => _iconScale = 2.0);
    await Future.delayed(Duration(milliseconds: 100));
    setState(() => _iconScale = 1.0);

    setState(() {
      hasLiked = !hasLiked;
      likeCount += hasLiked ? 1 : -1;
    });

    // Firestore like toggle
    await FirebaseService.instance.toggleLikeComment(
      widget.postId,
      widget.comment['commentId'],
      userId!,
    );

    String authorId = widget.comment['userId'];
    final selectedPostProvider = Provider.of<PostProvider>(
      context,
      listen: false,
    );
    final post = selectedPostProvider.selectedPost;

    // Get the post author's FCM token
    Map<String, dynamic> authorFCM = await FirebaseService.instance.getUserData(
      authorId,
    );
    String authorFcmToken = authorFCM['fcmToken'];

    // Send notification to the post author except the author like their own posts
    if (authorFcmToken.isNotEmpty &&
        userName != null &&
        userId != authorId) {
      NotificationService.sendPushNotification(
        targetToken: authorFcmToken,
        title: "$userName",
        body: "Liked your comment \n : ${widget.comment['comment']}",
      );

      try {
        await FirebaseService.instance.addNotification(
          targetUid: authorId,
          username: userName!,
          message: 'Liked your comment \n : ${widget.comment['comment']}',
          profileImage: profilePicture,
          postId: widget.postId,
          postThumbnail: post!.imageUrls[0],
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send notification')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, selectedPostProvider, child) {
        final selectedPost = selectedPostProvider.selectedPost;

        if (selectedPost == null) {
          return Center(child: CircularProgressIndicator());
        }

        return GestureDetector(
          onLongPress: () {
            highlight(); // trigger background change
            widget.onLongPress(widget.comment); // show copy/delete
          },
          child: Container(
            decoration: BoxDecoration(
              color:
              isHighlighted
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<Map<String, dynamic>?>(
                  future: FirebaseService.instance.getUserData(
                    widget.comment['userId'],
                  ),
                  builder: (context, snapshot) {
                    final userData = snapshot.data;
                    final profileUrl =
                        userData?['profilePictureUrl'] ??
                            'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg';

                    return CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(profileUrl),
                    );
                  },
                ),

                SizedBox(width: 10),

                //Wrap the Column in Expanded to fix width issues
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comment['username'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),

                      Text(widget.comment['comment'] ?? ''),

                      SizedBox(height: 2),
                      Text(
                        widget.comment['timestamp']
                            ?.toDate()
                            .toString()
                            .substring(0, 16) ??
                            '',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      //Testing
                    ],
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 1.0, end: _iconScale),
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Icon(
                              hasLiked ? Icons.favorite : Icons.favorite_border,
                              color: hasLiked ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 4),
                    likeCount == 0
                        ? SizedBox.shrink()
                        : Text(
                      likeCount.toString(),
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
