import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final List comments;

  PostDetailScreen({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController _commentController = TextEditingController();

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
              backgroundImage: AssetImage('assets/img.png'), // Admin profile image
            ),
            SizedBox(width: 8),
            Text("TARUMT Admin", style: TextStyle(color: Colors.black, fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Image
          Image.network(
            imageUrl,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
          ),

          // Post Title & Description
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Image.asset('assets/img.png', width: 20, height: 15), // Malaysia Flag
                //Title of the post
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 6),

                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: 18),
                Text(
                  "Yesterday 11:45", // Example timestamp
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Divider(),

          // Comment Section
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage('assets/img.png'), // User profile image
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comments[index]['name']!, style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text(comments[index]['comment']!),
                          SizedBox(height: 2),
                          Text(
                            comments[index]['time']!,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Comment Input Field
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundImage: AssetImage('assets/img.png')), // User Avatar
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
                  onPressed: () {
                    // TODO: Handle comment posting
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF203980),
                  ),
                  child: Text("Send", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
