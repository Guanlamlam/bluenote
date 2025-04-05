import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notifications = [
    {
      'username': 'YQ',
      'message': 'Liked Your Post',
      'date': '2024-03-17',
      'profileImage': 'assets/img.png', // Replace with actual asset path
      'postThumbnail': 'assets/img.png', // Replace with actual asset path
      'comment': '',
    },
    {
      'username': 'YQ',
      'message': 'Comment Your Post',
      'date': '2024-03-17',
      'profileImage': 'assets/img.png',
      'postThumbnail': 'assets/img.png',
      'comment': 'I love it!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(notification['profileImage']),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['username'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(notification['message']),
                              SizedBox(width: 10),
                              Text(
                                notification['date'],
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          if (notification['comment'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(notification['comment']),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        notification['postThumbnail'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 5),
                  ],
                ),
              ),
              Divider(
                color: Colors.grey[300], // Light grey color for the divider
                thickness: 1, // Optional: Adjust thickness if needed
              ), // Add a Divider after each notification
            ],
          );
        },
      ),
    );
  }
}
