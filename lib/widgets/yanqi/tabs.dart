import 'package:flutter/material.dart';
import 'package:bluenote/widgets/yanqi/lost_found_tab.dart';

class Tabs extends StatelessWidget {
  final String selectedTab;

  const Tabs({super.key, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Add third tab
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Post'),
              Tab(text: 'Liked'),
              Tab(text: 'Lost Found'), // New tab
            ],
          ),
          Container(
            height: 200,
            child: const TabBarView(
              children: [
                Center(child: Text('Post content for Post')),
                Center(child: Text('Liked content for Liked')),
                LostFoundTab(), // New content
              ],
            ),
          ),
        ],
      ),
    );
  }
}
