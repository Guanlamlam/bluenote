
import 'package:bluenote/screens/notifications_screen.dart';
import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/yanqi/auth/login_form.dart';
import 'package:flutter/material.dart';
import 'package:bluenote/screens/auth/user_profile_screen.dart';



class BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getCachedUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildBottomBar(context, 0); // Default with 0 count
        }

        final userId = snapshot.data!['userId'] ?? 'h';

        return StreamBuilder<int>(
          stream: FirebaseService.instance.getUnreadNotificationCountStream(userId),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return _buildBottomBar(context,unreadCount);
          },
        );

      },
    );
  }

  Widget _buildBottomBar(BuildContext context, int unreadCount) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 4.0,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: Icon(Icons.home), onPressed: () {}),
          SizedBox(width: 36),
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          SizedBox(width: 66),

          // 🔔 Real-time Notification Icon
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationsScreen()),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(width: 36),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

