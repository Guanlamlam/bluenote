import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bluenote/screens/update_lost_found.dart';

class LostFoundTab extends StatelessWidget {
  const LostFoundTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text("Please login to view Lost & Found posts"));
    }

    final stream = FirebaseFirestore.instance
        .collection('foundlost')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();


    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading posts'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No Lost & Found posts.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final images = (data['images'] as List<dynamic>?)?.cast<String>() ?? [];

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: images.isNotEmpty
                    ? Image.network(
                  images.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image),
                )
                    : const Icon(Icons.image_not_supported, size: 60),
                title: Text(data['item'] ?? ''),
                subtitle: Text(data['location'] ?? ''),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'Edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateLostFoundPage(
                            docId: docs[index].id,
                            data: data,
                          ),
                        ),
                      );
                    } else if (value == 'Delete') {
                      FirebaseFirestore.instance
                          .collection('foundlost')
                          .doc(docs[index].id)
                          .delete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Edit', child: Text('Edit')),
                    PopupMenuItem(value: 'Delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
