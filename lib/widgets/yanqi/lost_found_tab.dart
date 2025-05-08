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

        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,           // two columns
                  crossAxisSpacing: 8,         // horizontal gap
                  mainAxisSpacing: 8,          // vertical gap
                  childAspectRatio: 3 / 2,     // adjust ratio to taste
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final images = (data['images'] as List<dynamic>?)?.cast<String>() ?? [];

                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (images.isNotEmpty)
                            Image.network(
                              images.first,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                            )
                          else
                            const Icon(Icons.image_not_supported, size: 100),

                          const SizedBox(height: 8),

                          Text(
                            data['item'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          Text(
                            data['location'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const Spacer(),

                          Align(
                            alignment: Alignment.bottomRight,
                            child: PopupMenuButton<String>(
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
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'Edit', child: Text('Edit')),
                                PopupMenuItem(value: 'Delete', child: Text('Delete')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
