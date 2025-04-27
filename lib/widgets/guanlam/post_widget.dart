import 'package:bluenote/screens/post_detail_screen.dart';
import 'package:bluenote/service/notification_service.dart';
import 'package:bluenote/widgets/yanqi/auth/login_form.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bluenote/service/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';

class PostWidget extends StatefulWidget {
  final String postId;
  final String author;
  final String authorUid;
  final String title;
  final String content;
  final List<String> imageUrls;
  final int initialLikes;
  final User user;
  final Timestamp dateTime;

  const PostWidget({
    Key? key,
    required this.postId,
    required this.author,
    required this.authorUid,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.initialLikes,
    required this.user,
    required this.dateTime,
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late bool hasLiked;
  late int likeCount;

  Map<String, dynamic>? authorData;

  @override
  void initState() {
    super.initState();
    hasLiked = false;
    likeCount = widget.initialLikes;

    _checkIfUserLiked();
    _loadAuthorData();
  }

  Future<void> _loadAuthorData() async {
    try {
      final data = await FirebaseService.instance.getUserData(widget.authorUid);
      setState(() {
        authorData = data;
      });
    } catch (e) {
      print("Failed to fetch author data: $e");
    }
  }

  Future<void> _checkIfUserLiked() async {
    bool userHasLiked = await FirebaseService.instance.hasUserLiked(widget.postId, widget.user.uid);
    setState(() {
      hasLiked = userHasLiked;
    });
  }



  Future<void> _toggleLike() async {
    try {
      // Toggle like on Firestore
      await FirebaseService.instance.toggleLike(widget.postId, widget.user.uid);

      // Update local state
      setState(() {
        hasLiked = !hasLiked;
        likeCount = hasLiked ? likeCount + 1 : likeCount - 1;
      });

      // Send notification only when user likes the post (not when unliking)
      if (hasLiked) {
        // Get the post author's FCM token
        Map<String, dynamic> authorFCM = await FirebaseService.instance.getUserData(widget.authorUid);
        String authorFcmToken = authorFCM['fcmToken'];

        // Retrieve cached user info
        final userData = await getCachedUserData();
        String? userId = userData['userId'];
        String? username = userData['username'];
        String? profilePicture = userData['profilePictureUrl'];

        // Send notification to the post author
        if (authorFcmToken.isNotEmpty && username != null) {
          NotificationService.sendPushNotification(
              targetToken: authorFcmToken,
              title: "$username",
              body: "Liked your post"
          );

          try {
            await FirebaseService.instance.addNotification(
              targetUid: widget.authorUid,
              username: username,
              message: 'Liked your post',
              profileImage: profilePicture,
              postId: widget.postId,
              postThumbnail: widget.imageUrls[0],

            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send notification')),
            );
          }

        }
      }

    } catch (e) {
      // Show error to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling like: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              postId: widget.postId,
              author: widget.author,
              authorUid: widget.authorUid,
              title: widget.title,
              description: widget.content,
              imageUrls: widget.imageUrls,
              dateTime: widget.dateTime,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(12.0),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section - Dynamic height based on image size
            widget.imageUrls[0].isNotEmpty
                ? Container(
              width: double.infinity,
              // Dynamically adjust the image container height based on the image's aspect ratio
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[0],
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(Icons.error),
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
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 4),

                  // Content preview (truncated)
                  widget.content.isEmpty
                      ? SizedBox() // or any fallback widget
                      : Text(
                    widget.content,
                    style: TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )

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
                          child: Image.network(
                            authorData?['profilePictureUrl'] ?? 'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg', // You can use post['authorImageUrl'] if available
                            fit: BoxFit.cover,
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        widget.author,
                        style: TextStyle(fontSize: 14),
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
    );
  }
}
