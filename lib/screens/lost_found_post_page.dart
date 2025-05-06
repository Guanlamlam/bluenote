import 'package:flutter/material.dart';
import 'package:bluenote/service/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:bluenote/widgets/guanlam/bottom_nav_bar.dart';
import 'package:bluenote/widgets/guanlam/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bluenote/service/draft_database.dart';
import 'package:bluenote/model/draft_model.dart';
import 'package:intl/intl.dart';
import 'package:bluenote/service/sqlite_service.dart';
import 'package:bluenote/screens/draft_screen.dart';


class LostFoundPostPage extends StatefulWidget {
  final int? draftId;
  const LostFoundPostPage({Key? key, this.draftId}) : super(key: key);
  @override _LostFoundPostPageState createState() => _LostFoundPostPageState();
}

class _LostFoundPostPageState extends State<LostFoundPostPage> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String selectedType = "Found";
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  Map<String, dynamic>? _editingDraft;

  @override
  void initState() {
    super.initState();
    Permission.camera.request();
    Permission.photos.request();
    Permission.storage.request();

    if (widget.draftId != null) {
      _loadDraft(widget.draftId!);
    }
  }

  Future<void> _loadDraft(int id) async {
    final draft = await SQLiteService.instance.getDraftById(id);
    if (draft != null) {
      setState(() {
        _editingDraft = draft;
        _itemNameController.text = draft['item'] ?? '';
        _contactNameController.text = draft['contact'] ?? '';
        _contactNumberController.text = draft['contactnumber'] ?? '';
        _locationController.text = draft['location'] ?? '';
        selectedType = draft['type'] ?? 'Found';
        _selectedImages.clear();
        // restore image file paths
        final paths = (draft['imagePaths'] as String).split('||');
        for (var p in paths) {
          if (p.isNotEmpty) _selectedImages.add(File(p));
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only select up to 3 images.')),
      );
      return;
    }
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Widget _buildImagePreview(File img) => Image.file(img, width: 80, height: 80, fit: BoxFit.cover);

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

  Future<void> _submitPost() async {
    final item = _itemNameController.text.trim();
    final contact = _contactNameController.text.trim();
    final contactNumber = _contactNumberController.text.trim();
    final location = _locationController.text.trim();

    if (item.isEmpty || contact.isEmpty || contactNumber.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        for (File imageFile in _selectedImages) {
          final url = await FirebaseService.instance.uploadToCloudinary(imageFile);
          if (url != null) imageUrls.add(url);
        }
      }
      if (imageUrls.isEmpty) imageUrls = [''];

      await FirebaseFirestore.instance.collection('foundlost').add({
        'item': item,
        'contact': contact,
        'contactnumber': contactNumber,
        'location': location,
        'type': selectedType,
        'images': imageUrls,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // if editing a draft, delete it
      if (_editingDraft != null && _editingDraft!['id'] != null) {
        await SQLiteService.instance.deleteDraft(_editingDraft!['id']);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: \$e')),
      );
    }
  }

  Future<void> _saveToDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final draft = {
      'id': widget.draftId,
      'item': _itemNameController.text.trim(),
      'contact': _contactNameController.text.trim(),
      'contactnumber': _contactNumberController.text.trim(),
      'location': _locationController.text.trim(),
      'type': selectedType,
      'imagePaths': _selectedImages.map((f) => f.path).join('||'),
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await SQLiteService.instance.insertDraft(draft);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved locally')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save draft: \$e')),
      );
    }
  }

  Widget _buildTypeButton(String type, Color primaryColor) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          type,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF203980);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Post Found/Lost",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ..._selectedImages.map((image) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImagePreview(image),
                      ),
                      Positioned(
                        top: 0, right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.remove(image)),
                          child: const CircleAvatar(
                            radius: 10, backgroundColor: Colors.white,
                            child: Icon(Icons.close, size: 14, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (_selectedImages.length < 3)
                  GestureDetector(
                    onTap: _showImagePickerDialog,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add, size: 30, color: Colors.black54),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _itemNameController, decoration: const InputDecoration(hintText: 'Enter Item Name', border: InputBorder.none)),
            const SizedBox(height: 8),
            TextField(controller: _contactNameController, decoration: const InputDecoration(hintText: 'Enter Contact Name', border: InputBorder.none)),
            const SizedBox(height: 8),
            TextField(controller: _contactNumberController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Enter Contact Number', border: InputBorder.none)),
            const SizedBox(height: 8),
            TextField(controller: _locationController, decoration: const InputDecoration(hintText: 'Enter Location', border: InputBorder.none)),
            const SizedBox(height: 16),
            Row(children: [_buildTypeButton("Found", primaryColor), const SizedBox(width: 8), _buildTypeButton("Lost", primaryColor)]),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saveToDraft,
                    style: OutlinedButton.styleFrom(side: BorderSide(color: primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text("Save to Draft", style: TextStyle(color: primaryColor, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text("Post", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.drafts, color: Colors.white),  // Set icon color
        label: const Text('Drafts', style: TextStyle(color: Colors.white)),  // Set text color
        backgroundColor: primaryColor,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DraftScreen()),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
