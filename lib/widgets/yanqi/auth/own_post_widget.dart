import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluenote/providers/post_provider.dart';
import 'package:bluenote/screens/post_detail_screen.dart';
import 'package:bluenote/service/notification_service.dart';
import 'package:bluenote/widgets/guanlam/models/post_model.dart';
import 'package:bluenote/widgets/yanqi/auth/login_form.dart';
import 'package:bluenote/widgets/yanqi/auth/post_detail_yq_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bluenote/service/firebase_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class OwnPostWidget extends StatefulWidget {
  final PostModel post;

  const OwnPostWidget({
    super.key,
    required this.post,
  });

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<OwnPostWidget> {
  String? userId;
  String? userName;
  String? profilePicture;

  late bool hasLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    hasLiked = false;
    likeCount = widget.post.likes;
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserData(); // Ensure userId is set
    await _checkIfUserLiked(); // Now safe to check
  }

  // Fetch user data asynchronously in initState()
  Future<void> _loadUserData() async {
    // Retrieve cached user info
    final userData = await getCachedUserData();
    userId = userData['userId'];
    userName = userData['username'];
    profilePicture = userData['profilePictureUrl'];
  }

  Future<void> _checkIfUserLiked() async {
    bool userHasLiked = await FirebaseService.instance.hasUserLiked(
      widget.post.postId,
      userId!,
    );
    setState(() {
      hasLiked = userHasLiked;
    });
  }

  Future<void> _toggleLike() async {
    try {
      // Update local state
      setState(() {
        hasLiked = !hasLiked;
        likeCount = hasLiked ? likeCount + 1 : likeCount - 1;
      });
      // Toggle like on Firestore
      await FirebaseService.instance.toggleLike(
        widget.post.postId,
        userId!,
      );

      // Send notification only when user likes the post (not when unliking)
      if (hasLiked) {
        // Get the post author's FCM token
        Map<String, dynamic> authorFCM = await FirebaseService.instance
            .getUserData(widget.post.authorUid);
        String authorFcmToken = authorFCM['fcmToken'];

        // Retrieve cached user info
        final userData = await getCachedUserData();
        String? userId = userData['userId'];
        String? username = userData['username'];
        String? profilePicture = userData['profilePictureUrl'];

        // Send notification to the post author except the author like their own posts
        if (authorFcmToken.isNotEmpty &&
            username != null &&
            userId != widget.post.authorUid) {
          NotificationService.sendPushNotification(
            targetToken: authorFcmToken,
            title: username,
            body: "Liked your post",
          );

          try {
            await FirebaseService.instance.addNotification(
              targetUid: widget.post.authorUid,
              username: username,
              message: 'Liked your post',
              profileImage: profilePicture,
              postId: widget.post.postId,
              postThumbnail: widget.post.imageUrls[0],
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ ❌ Failed to send notification')),
            );
          }
        }
      }
    } catch (e) {
      // Show error to the user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error toggling like: $e')));
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return GestureDetector(
      onTap: () {
        Provider.of<PostProvider>(context, listen: false).setSelectedPost(post);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailYqScreen()),
        );
      },

      child: Container(

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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Image Section - Dynamic height based on image size
              post.imageUrls[0].isNotEmpty
                  ? Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: 250, // Set the minimum height
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrls[0],
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
              )
                  : Container(), // Empty container if no image
              // Text Content Section - Dynamically adjust based on content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    AutoSizeText(
                      post.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      minFontSize: 12, // Minimum font size
                      maxFontSize: 24, // Maximum font size
                    ),
                  ],
                ),
              ),

              // Author and Like Section - Adjusts based on space available
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Author Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl:
                              post.authorData!['profilePictureUrl'].isEmpty
                                  ? 'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg'
                                  : post.authorData!['profilePictureUrl'],
                              imageBuilder:
                                  (context, imageProvider) => Container(
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
                              placeholder:
                                  (context, url) => const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget:
                                  (context, url, error) =>
                              const Icon(Icons.error, size: 32),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),

                        // Text(
                        //   widget.author,
                        //   style: TextStyle(fontSize: 14),
                        // ),
                        AutoSizeText(
                          post.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 10, // Minimum font size
                          maxFontSize: 12, // Maximum font size
                        ),
                      ],
                    ),

                    // Like Button and Count
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Icon(
                            hasLiked ? Icons.favorite : Icons.favorite_border,
                            color: hasLiked ? Colors.red : Colors.grey,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          likeCount.toString(),
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
