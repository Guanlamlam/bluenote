import 'package:bluenote/screens/home_screen.dart';
import 'package:bluenote/screens/notifications_screen.dart';
import 'package:bluenote/screens/dashboard_screen.dart';
import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/yanqi/auth/login_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bluenote/screens/auth/user_profile_screen.dart';
import 'package:bluenote/screens/conversation_list_screen.dart';

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
            return _buildBottomBar(context, unreadCount);
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
          // Home Icon
          IconButton(icon: Icon(Icons.home), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }),

          SizedBox(width: 38),

          // Search Icon
          IconButton(icon: Icon(Icons.search), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          }),

          SizedBox(width: 68), // Space for FAB

          // Messages Icon (without count)
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConversationListScreen()),
              );
            },
          ),

          SizedBox(width: 36),

          // User Profile Icon
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
