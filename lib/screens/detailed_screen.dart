import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:bluenote/widgets/guanlam/bottom_nav_bar.dart';
// import 'package:bluenote/widgets/guanlam/custom_app_bar.dart';
// import 'dart:io' show Platform;


/// A screen that shows full details of a Lost & Found entry.
/// Expects all fields passed via constructor.
class DetailedScreen extends StatelessWidget {
  final String item;
  final String contactName;
  final String contactNumber;
  final String location;
  final DateTime timestamp;
  final List<String> images;

  const DetailedScreen({
    Key? key,
    required this.item,
    required this.contactName,
    required this.contactNumber,
    required this.location,
    required this.timestamp,
    required this.images,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMMMMd().add_jm();

    return Scaffold(
      // appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Back Arrow and Title Row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Post Detail",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Images Section
            if (images.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        images[index],
                        width: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 250,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Item Details
            Text(
              'Item: $item',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Text(
              'Contact Name: $contactName',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),

            Text(
              'Contact Number: $contactNumber',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),

            Text(
              'Location: $location',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),

            // Formatted Date/Time
            Text(
              'Date/Time: ${formatter.format(timestamp.toLocal())}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 24),
            // Contact via WhatsApp Button
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Contact WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
                onPressed: () async {
                  final phone = contactNumber.replaceAll(RegExp(r'\D'), '');

                  final text = Uri.encodeComponent(
                    'Hi $contactName, I saw your lost-and-found post about "$item". Is it still available?',
                  );

                  final uri = Uri.parse('whatsapp://send?phone=$phone&text=$text');

                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WhatsApp not installed or failed to open.'),
                      ),
                    );
                  }

                },
            )

          ],
        ),
      ),
      // bottomNavigationBar: BottomNavBar(),
    );
  }
}
