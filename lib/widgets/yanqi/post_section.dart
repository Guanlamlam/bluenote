import 'package:flutter/material.dart';

class PostSection extends StatelessWidget {
  const PostSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Post Content',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          IconButton(
            onPressed: () {
              // Handle more options
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}
