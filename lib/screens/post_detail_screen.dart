import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/guanlam/image_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class PostDetailScreen extends StatefulWidget {
  final String title;
  final String description;
  final List<String> imageUrls;

  final String postId;
  final String author;

  final Timestamp dateTime;

  PostDetailScreen({
    required this.title,
    required this.description,
    required this.imageUrls,

    required this.postId,
    required this.author,
    required this.dateTime,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late FirebaseService _firebaseService;
  late User? user;
  Map<String, dynamic> userData = {};

  final TextEditingController _commentController = TextEditingController();

  int _currentPageIndex = 0;
  int commentCount = 0; // Track the comment count

  // To track the page number (e.g., 1/5, 2/5, etc.)
  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _loadUserData();
    _fetchCommentCount();
  }

  // Fetch user data asynchronously in initState()
  Future<void> _loadUserData() async {
    user =
        _firebaseService.getCurrentUser(); // Assuming getCurrentUser() is async
    if (user != null) {
      userData = await _firebaseService.getUserData(
        user!.uid,
      ); // Assuming this returns a List<Map<String, dynamic>>
    }
  }

  // Fetch the comment count
  Future<void> _fetchCommentCount() async {
    int count = await _firebaseService.getCommentCount(widget.postId);
    setState(() {
      commentCount = count;
    });
  }

  void _showCommentOptions(
    BuildContext context,
    Map<String, dynamic> comment,
    String postId,
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
            ListTile(
              leading: Icon(Icons.copy, color: Colors.blueAccent),
              title: Text("Copy Comment"),
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
            //If comment is created by yourself, can deleted
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.redAccent),
              title: Text("Delete Comment"),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet first
                _showDeleteConfirmationDialog(context, postId, comment['id']);
              },
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
                _firebaseService.deleteComment(context, postId, commentId);
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

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _commentController.dispose();
  }

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
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                'https://st3.depositphotos.com/15648834/17930/v/450/depositphotos_179308454-stock-illustration-unknown-person-silhouette-glasses-profile.jpg',
              ), // Admin profile image
            ),
            SizedBox(width: 8),
            Text(
              widget.author,
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageUrls[0].isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 280, // Or make dynamic later
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: widget.imageUrls.length,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ImageView(
                                          imageUrls: widget.imageUrls,
                                        ),
                                  ),
                                );
                              },
                              child: InteractiveViewer(
                                panEnabled: true,
                                scaleEnabled: true,
                                minScale: 0.5,
                                maxScale: 3.0,
                                child: Image.network(
                                  widget.imageUrls[index],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),

                        // Top-right index number
                        if (widget.imageUrls.length > 1)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${_currentPageIndex + 1} / ${widget.imageUrls.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bullet indicators
                  if (widget.imageUrls.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.imageUrls.length,
                          (index) => AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  _currentPageIndex == index
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              SizedBox(), // If no image
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
                    widget.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 6),

                  Text(
                    widget.description,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 18),
                  Text(
                    DateFormat(
                      'dd-MM-yyyy HH:mm ',
                    ).format(widget.dateTime.toDate()), // Example timestamp
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Divider(),
            // Comment Input Field
            SizedBox(height: 10,),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Text(
                '$commentCount comments',
                style: TextStyle(color: Colors.grey),
              ),
            ),


            SizedBox(height: 20,),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                // boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/img.png'),
                  ), // User Avatar
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
                      if (_commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a comment')),
                        );
                        return; // exit early
                      }

                      await _firebaseService.addComment(
                        postId: widget.postId,
                        userId: user?.uid ?? '',
                        username: userData['username'],
                        comment: _commentController.text.trim(),
                      );

                      _commentController.clear(); // ✅ Clear the input
                      FocusScope.of(context).unfocus(); // 👈 hide keyboard
                      setState(
                        () {
                          commentCount++;
                        },
                      ); // ✅ Rebuild the widget to trigger FutureBuilder to refresh
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF203980),
                    ),
                    child: Text("Send", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Comment Section
            // ⬇️ Comments Section with FutureBuilder
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _firebaseService.getComments(widget.postId),
              builder: (context, snapshot) {
                // No need this code it will occur reloading when post a comments and trying to delete
                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return Center(child: CircularProgressIndicator());
                // }
                if (snapshot.hasError) {
                  return Center(child: Text("Failed to load comments"));
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(child: Text("No comments yet."));
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
                          postId: widget.postId,
                          user: user,
                          onLongPress:
                              (selectedComment) => _showCommentOptions(
                                context,
                                selectedComment,
                                widget.postId,
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
  }
}





class CommentTile extends StatefulWidget {
  final Map<String, dynamic> comment;
  final String postId;
  final Function(Map<String, dynamic>) onLongPress;
  final User? user;

  const CommentTile({
    required this.comment,
    required this.postId,
    required this.onLongPress,
    required this.user,
    super.key,
  });

  @override
  _CommentTileState createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool isHighlighted = false;
  bool hasLiked = false;

  FirebaseService firebaseService = FirebaseService();
  double _iconScale = 1.0;

  @override
  void initState() {
    super.initState();
    _checkIfLiked(); // 🔥 Check from Firestore
  }

  Future<void> _checkIfLiked() async {
    if (widget.user == null) return;

    final likeDoc = await firebaseService.checkIfLiked(
      widget.postId,
      widget.comment['id'],
      widget.user!.uid,
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
      widget.comment['likes'] =
          (widget.comment['likes'] ?? 0) + (hasLiked ? 1 : -1);
    });

    // Firestore like toggle
    await firebaseService.toggleLikeComment(
      widget.postId,
      widget.comment['id'],
      widget.user!.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        highlight(); // trigger background change
        widget.onLongPress(widget.comment); // show copy/delete
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isHighlighted ? Colors.grey.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                'https://st3.depositphotos.com/15648834/17930/v/450/depositphotos_179308454-stock-illustration-unknown-person-silhouette-glasses-profile.jpg',
              ),
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
                    widget.comment['timestamp']?.toDate().toString().substring(
                          0,
                          16,
                        ) ??
                        '',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                widget.comment['likes'] == 0 || widget.comment['likes'] == null
                    ? SizedBox.shrink()
                    : Text(
                      widget.comment['likes'].toString(),
                      style: TextStyle(fontSize: 14),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
