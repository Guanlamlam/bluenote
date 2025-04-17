
import 'package:bluenote/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:bluenote/screens/auth/user_profile_screen.dart';

class BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 4.0,
      color: Colors.white, //background color white
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: Icon(Icons.home), onPressed: () {}),
          SizedBox(width: 38), // Space for FAB
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          SizedBox(width: 68), // Space for FAB
          IconButton(icon: Icon(Icons.notifications), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsScreen()),
            );

          }),
          SizedBox(width: 38), // Space for FAB
          IconButton(icon: Icon(Icons.person), onPressed: () {  Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfileScreen()),
          );

          }),
        ],
      ),
    );
  }
}
