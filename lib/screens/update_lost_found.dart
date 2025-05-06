import 'dart:io';
import 'package:bluenote/service/firebase_service.dart'; // your Cloudinary service
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdateLostFoundPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const UpdateLostFoundPage({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<UpdateLostFoundPage> createState() => _UpdateLostFoundPageState();
}

class _UpdateLostFoundPageState extends State<UpdateLostFoundPage> {
  late TextEditingController _itemController;
  late TextEditingController _contactController;
  late TextEditingController _contactNumberController;
  late TextEditingController _locationController;
  String selectedType = "Found";

  // mirror PostScreen: one list for existing URLs, one for new Files
  List<String> _imageUrls = [];
  List<File> _selectedImages = [];

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _itemController =
        TextEditingController(text: widget.data['item'] ?? '');
    _contactController =
        TextEditingController(text: widget.data['contact'] ?? '');
    _contactNumberController =
        TextEditingController(text: widget.data['contactnumber'] ?? '');
    _locationController =
        TextEditingController(text: widget.data['location'] ?? '');
    selectedType = widget.data['type'] ?? "Found";

    // initialize URL list
    final incoming = widget.data['images'];
    if (incoming != null && incoming is List) {
      _imageUrls = List<String>.from(incoming);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imageUrls.length + _selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 images allowed')),
      );
      return;
    }
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _selectedImages.add(File(picked.path)));
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<List<String>> _uploadLocalImages() async {
    List<String> urls = [];
    for (var file in _selectedImages) {
      final url =
      await FirebaseService.instance.uploadToCloudinary(file);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  Future<void> _updatePost() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // upload new files
      final newUrls = await _uploadLocalImages();
      // merge with existing URLs
      final allUrls = [..._imageUrls, ...newUrls];
      // if no images at all, Firestore will store empty list
      await FirebaseFirestore.instance
          .collection('foundlost')          // ← your collection
          .doc(widget.docId)
          .update({
        'item': _itemController.text.trim(),
        'contact': _contactController.text.trim(),
        'contactnumber': _contactNumberController.text.trim(),
        'location': _locationController.text.trim(),
        'type': selectedType,
        'images': allUrls,
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTypeButton(String type) {
    final selected = selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF203980) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(type,
            style: TextStyle(color: selected ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Row(
      children: [
        // existing URL images
        ..._imageUrls.map((url) {
          if (url.isEmpty) return SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url,
                      width: 80, height: 80, fit: BoxFit.cover),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _imageUrls.remove(url);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.black),
                    ),
                  ),
                )
              ],
            ),
          );
        }),
        // newly picked files
        ..._selectedImages.map((file) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(file,
                      width: 80, height: 80, fit: BoxFit.cover),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedImages.remove(file));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.black),
                    ),
                  ),
                )
              ],
            ),
          );
        }),
        // add button
        if (_imageUrls.length + _selectedImages.length < 3)
          GestureDetector(
            onTap: _showImagePickerDialog,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add, size: 30, color: Colors.black54),
            ),
          ),
      ],
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 16),
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
              decoration:
              const InputDecoration(labelText: 'Contact Number'),
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
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF203980),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Update Post',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
