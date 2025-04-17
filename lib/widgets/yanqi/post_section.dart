import 'package:flutter/material.dart';

class PostSection extends StatelessWidget {
  const PostSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Post', style: TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Handle post actions (e.g., delete, edit)
              },
            ),
          ],
        ),
      ),
    );
  }
}
