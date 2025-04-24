
import 'package:bluenote/screens/post_detail_screen.dart';
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
  final String title;
  final String content;
  final String imageUrl;
  final int initialLikes;
  final List comments;
  final FirebaseService firebaseService;
  final User user;
  final Timestamp dateTime;


  const PostWidget({
    Key? key,
    required this.postId,
    required this.author,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.initialLikes,
    required this.comments,
    required this.firebaseService,
    required this.user,
    required this.dateTime,
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late bool hasLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    hasLiked = false;
    likeCount = widget.initialLikes;

    _checkIfUserLiked();
  }

  Future<void> _checkIfUserLiked() async {
    bool userHasLiked = await widget.firebaseService.hasUserLiked(widget.postId, widget.user.uid);
    setState(() {
      hasLiked = userHasLiked;
    });
  }

  Future<void> _toggleLike() async {
    // Toggle like on Firestore
    await widget.firebaseService.toggleLike(widget.postId, widget.user.uid);

    // Update local state
    setState(() {
      hasLiked = !hasLiked;
      likeCount = hasLiked ? likeCount + 1 : likeCount - 1;
    });
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
              title: widget.title,
              description: widget.content,
              imageUrl: widget.imageUrl,
              comments: widget.comments,
              dateTime:widget.dateTime,

            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          constraints: BoxConstraints(minHeight: 250),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1, // Limit to one line
                        overflow: TextOverflow.ellipsis, // Add "..." if it overflows
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.transparent,
                              child: ClipOval(
                                child: Image.network(
                                  'https://wallpapers.com/images/featured/cute-profile-picture-s52z1uggme5sj92d.jpg', // you could use post['authorImageUrl'] if you have one
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
