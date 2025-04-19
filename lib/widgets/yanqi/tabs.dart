import 'package:flutter/material.dart';

class Tabs extends StatelessWidget {
  final String selectedTab;

  const Tabs({super.key, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Post'),
              Tab(text: 'Liked'),
            ],
          ),
          Container(
            height: 200, // Adjust as needed
            child: TabBarView(
              children: [
                Center(child: Text('Post content for $selectedTab')),
                Center(child: Text('Liked content for $selectedTab')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
