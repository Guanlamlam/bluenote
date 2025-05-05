import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdateLostFoundPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const UpdateLostFoundPage({super.key, required this.docId, required this.data});

  @override
  State<UpdateLostFoundPage> createState() => _UpdateLostFoundPageState();
}

class _UpdateLostFoundPageState extends State<UpdateLostFoundPage> {
  late TextEditingController _itemController;
  late TextEditingController _contactController;
  late TextEditingController _contactNumberController;
  late TextEditingController _locationController;
  String selectedType = "Found";

  // Separate lists for network and local images
  List<String> networkImages = [];
  List<File> localImages = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController(text: widget.data['item']);
    _contactController = TextEditingController(text: widget.data['contact']);
    _contactNumberController = TextEditingController(text: widget.data['contactnumber']);
    _locationController = TextEditingController(text: widget.data['location']);
    selectedType = widget.data['type'] ?? "Found";

    // Initialize network images from Firestore data
    networkImages = List<String>.from(widget.data['images'] ?? []);
  }

  Future<void> _pickImage() async {
    if (networkImages.length + localImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 images allowed')),
      );
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        localImages.add(File(picked.path));
      });
    }
  }

  Future<List<String>> _uploadLocalImages() async {
    List<String> uploadedUrls = [];
    for (var file in localImages) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child('images/$fileName');
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  Future<void> _updatePost() async {
    // 1. Upload any new local images
    final newUrls = await _uploadLocalImages();

    // 2. Combine existing network images with newly uploaded URLs
    final allUrls = [...networkImages, ...newUrls];

    // 3. Update Firestore document
    await FirebaseFirestore.instance
        .collection('foundlost')
        .doc(widget.docId)
        .update({
      'item': _itemController.text.trim(),
      'contact': _contactController.text.trim(),
      'contactnumber': _contactNumberController.text.trim(),
      'location': _locationController.text.trim(),
      'type': selectedType,
      'images': allUrls,
    });

    // 4. Pop back, optionally return true to signal refresh
    Navigator.pop(context, true);
  }

  Widget _buildTypeButton(String type) {
    final bool isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF203980) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      ),
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _contactController.dispose();
    _contactNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Lost & Found')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Item'),
            ),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            TextField(
              controller: _contactNumberController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeButton("Found"),
                const SizedBox(width: 10),
                _buildTypeButton("Lost"),
              ],
            ),

            const SizedBox(height: 16),
            const Text("Existing Images (from server):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                ...networkImages.map((url) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => networkImages.remove(url)),
                    ),
                  ],
                )),
              ],
            ),

            const SizedBox(height: 16),
            const Text("New Images (local):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                ...localImages.map((file) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => localImages.remove(file)),
                    ),
                  ],
                )),
                // Conditional add button
                if (networkImages.length + localImages.length < 3)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.add),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _updatePost,
                child: const Text('Update Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
