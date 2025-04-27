import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/yanqi/auth/login_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  List<Map<String, dynamic>> notifications = [];


  @override
  void initState(){
    super.initState();
    _loadNotifications();

  }

  Future<void> _loadNotifications() async {
    final userData = await getCachedUserData();
    String? userId = userData['userId'];

    if (userId != null) {
      final fetchedNotifications = await FirebaseService.instance.getNotifications(userId);
      fetchedNotifications.sort((a, b) {
        bool aViewed = a['viewed'] ?? false;
        bool bViewed = b['viewed'] ?? false;

        if (!aViewed && bViewed) {
          return -1; // a is unread → comes first
        } else if (aViewed && !bViewed) {
          return 1;  // b is unread → comes first
        }
        return 0; // same status → keep current order
      });


      setState(() {
        notifications = fetchedNotifications;
      });
      print('✅✅✅✅✅Fetched Notifications: $fetchedNotifications');
    }
  }



  String _formatTimestamp(dynamic timestamp) {
    DateTime? date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      return timestamp; // fallback
    }

    if (date != null) {
      final year = date.year;
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return "$year-$month-$day $hour:$minute";
    }

    return "Unknown";
  }






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
          return Dismissible(
            key: Key(notification['id'] ?? index.toString()), // Make sure 'id' exists or use index fallback
            direction: DismissDirection.endToStart, // swipe from right to left
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              color: Colors.red,
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) async{
              final notificationId = notification['id'];
              final userData = await getCachedUserData();
              final userId = userData['userId'];

              setState(() {
                notifications.removeAt(index);
              });

              if (userId != null && notificationId != null) {
                await FirebaseService.instance.deleteNotification(userId, notificationId);
              }
              // FirebaseService.instance.deleteNotification(notification['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Notification deleted")),
              );
            },
            child: GestureDetector(
              onTap: () async {
                final notificationId = notification['id'];
                final userData = await getCachedUserData();
                final userId = userData['userId'];

                if (userId != null && notificationId != null && !(notification['viewed'] ?? false)) {
                  await FirebaseService.instance.markNotificationAsViewed(userId, notificationId);

                  setState(() {
                    notifications[index]['viewed'] = true; // 👈 Update UI
                  });
                }

                // You can also navigate to detail page here if needed
              },
              child: Column(
                children: [
                  Container(
                    color: (notification['viewed'] ?? false) ? Colors.white : Colors.grey[200],// grey background if viewed
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            (notification['profileImage'] ?? '').isNotEmpty
                                ? notification['profileImage']
                                : 'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg',
                          ),
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
                                    _formatTimestamp(notification['timestamp']),
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            (notification['postThumbnail'] ?? '').isNotEmpty
                                ? notification['postThumbnail']
                                : 'https://media-cdn.tripadvisor.com/media/photo-s/10/c4/23/16/highland-view-bed-and.jpg',
                            width: 45,
                            height: 45,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 5),
                      ],
                    ),
                  ),

                  // Divider(
                  //   color: Colors.grey[300], // Light grey color for the divider
                  //   thickness: .1, // Optional: Adjust thickness if needed
                  // ), // Add a Divider after each notification
                ],
              )
            ),

          );

        },
      ),
    );
  }
}








