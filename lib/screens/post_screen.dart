import 'package:bluenote/service/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

// Future<void> _requestPermissions() async {
//   await [
//     Permission.camera,
//     Permission.photos,
//     Permission.storage,
//   ].request();
// }

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String selectedCategory = "Events"; // Default selected category

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isLoading = false;



  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only select up to 3 images.')),
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

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take a Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ..._selectedImages.map((image) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              image,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -5,
                            right: -5,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.remove(image);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2), // subtle drop shadow
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.close, size: 14, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                )),
                if (_selectedImages.length < 3)
                  GestureDetector(
                    onTap: _showImagePickerDialog,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, size: 30, color: Colors.black54),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter Title',
                border: InputBorder.none,
              ),
            ),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter Content',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildCategoryButton("Events"),
                SizedBox(width: 8),
                _buildCategoryButton("Q&A"),
              ],
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill in the title fields.')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true); // Start loading

                  try {
                    // 1. Initialize an empty list for image URLs
                    List<String> imageUrls = [];

                    // 2. Only attempt to upload if there are images selected
                    if (_selectedImages.isNotEmpty) {
                      for (File imageFile in _selectedImages) {
                        final imageUrl = await FirebaseService.instance.uploadToCloudinary(imageFile);
                        if (imageUrl != null) {
                          imageUrls.add(imageUrl);
                        }
                      }
                    }

                    // 3. If no images are uploaded, make sure imageUrls contains [""].
                    if (imageUrls.isEmpty) {
                      imageUrls = [""];  // Assign [""] if no image URLs are added
                    }

                    // 4. Upload post data + image URLs to Firebase
                    await FirebaseService.instance.uploadPost(
                      title: _titleController.text.trim(),
                      content: _contentController.text.trim(),
                      category: selectedCategory,
                      imageUrls: imageUrls, // Pass the list of image URLs
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Post uploaded successfully!')),
                    );

                    Navigator.pop(context);  // Go back after posting
                  } catch (e) {
                    print(e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to upload post.')),
                    );
                  }finally {
                    if (mounted) setState(() => _isLoading = false); // Stop loading
                  }
                },


                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF203980), // Match button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text("Post", style: TextStyle(color: Colors.white, fontSize: 16)),

              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedCategory == category ? Color(0xFF203980) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: selectedCategory == category ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}


