import 'package:flutter/material.dart';

class Tabs extends StatelessWidget {
  final String selectedTab;

  const Tabs({super.key, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tabButton(context, 'Post', selectedTab),
        const SizedBox(width: 16),
        _tabButton(context, 'Liked', selectedTab),
      ],
    );
  }

  Widget _tabButton(BuildContext context, String title, String selectedTab) {
    return ElevatedButton(
      onPressed: () {
        // Handle tab change
      },
      child: Text(title),
      style: ElevatedButton.styleFrom(
        foregroundColor: selectedTab == title ? Colors.white : Colors.blue, backgroundColor: selectedTab == title ? Colors.blue : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: Colors.blue),
      ),
    );
  }
}
