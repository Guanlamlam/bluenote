
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckingFirebaseScreen extends StatefulWidget {
  const CheckingFirebaseScreen({super.key});

  @override
  State<CheckingFirebaseScreen> createState() => _CheckingFirebaseScreenState();
}

class _CheckingFirebaseScreenState extends State<CheckingFirebaseScreen> {
  final TextEditingController _titleController = TextEditingController();

  // Method to add a new post to Firestore
  Future<void> addPost() async {
    CollectionReference posts = FirebaseFirestore.instance.collection('post');

    // Add post with title and initial like count
    await posts.add({
      'title': _titleController.text,  // Get title from the text input
      'like': 0,  // Initial like count is 0
    });

    // Clear the text field after adding the post
    _titleController.clear();
  }

  // Method to like a post (increment the 'like' field)
  Future<void> likePost(DocumentReference postRef, int currentLikes) async {
    // Increment like count by 1
    await postRef.update({
      'like': currentLikes + 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Testing Firebase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to Firebase Firestore Example'),
            SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Enter Post Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                addPost();  // Add the post to Firestore
              },
              child: Text('Add Post'),
            ),
            SizedBox(height: 20),
            // Display posts in real-time using StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('post').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var posts = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      var post = posts[index];
                      var postRef = post.reference;  // Reference to the specific post document
                      int likeCount = post['like'];  // Get current like count

                      return ListTile(
                        title: Text(post['title']),  // Display the post title
                        subtitle: Row(
                          children: [
                            Text('Likes: $likeCount'),  // Display current like count
                            IconButton(
                              icon: Icon(
                                likeCount > 0 ? Icons.favorite : Icons.favorite_border,
                                color: likeCount > 0 ? Colors.red : Colors.black,
                              ),
                              onPressed: () {
                                likePost(postRef, likeCount);  // Like the post (increment like)
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
