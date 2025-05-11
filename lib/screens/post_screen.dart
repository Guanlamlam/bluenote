import 'dart:convert';

import 'package:bluenote/providers/post_provider.dart';
import 'package:bluenote/service/firebase_service.dart';
import 'package:bluenote/widgets/guanlam/app_snack_bar.dart';
import 'package:bluenote/widgets/guanlam/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class PostScreen extends StatefulWidget {
  final PostModel? post; // Optional parameter for editing

  const PostScreen({super.key, this.post});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with WidgetsBindingObserver {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String selectedCategory = "Events"; // Default selected category

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>(); // GlobalKey for Form state
  bool _shouldSaveDraft = true;

  List<String> _imageUrls = []; // Separate list for image URLs (Cloudinary)
  @override
  void initState() {
    super.initState();
    // If editing, load the existing post data
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _contentController.text = widget.post!.content;
      selectedCategory = widget.post!.category;
      _selectedImages.clear(); // Clear any previously selected images

      // Check if the post contains images, then separate the URL images and local files
      for (var url in widget.post!.imageUrls) {
        if (url.isNotEmpty) {
          _imageUrls.add(url); // It's a URL from Cloudinary
        }
      }
    }
    WidgetsBinding.instance.addObserver(
      this,
    ); // Register as observer for app lifecycle
    _checkForDraft();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      AppSnackBar.show(context, "You can only select up to 3 images.");

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
      builder:
          (context) => Wrap(
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

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true); // Start loading

      try {
        // _imageUrls: Used for all images associated with the post (existing and new)
        // imageUrls: Used only for new uploads (local images picked from the phone)

        // Initialize an empty list for image URLs
        List<String> imageUrls = [];


        // 1. Upload only the new images
        if (_selectedImages.isNotEmpty) {
          for (File imageFile in _selectedImages) {
            final imageUrl = await FirebaseService.instance.uploadToCloudinary(imageFile);
            if (imageUrl != null) {
              imageUrls.add(imageUrl); //for local image
              _imageUrls.add(imageUrl); //for remote image
            }
          }
        }

        // 2. If no images are uploaded, make sure imageUrls contains [""] (empty placeholder)
        if (_imageUrls.isEmpty) {
          _imageUrls = [""];
        }
        if (imageUrls.isEmpty){
          imageUrls = [""];
        }



        // 3. Handle the update (either new post or update an existing post)
        if (widget.post == null) {
          // New post
          final newPost = await FirebaseService.instance.uploadPost(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            category: selectedCategory,
            imageUrls: imageUrls,
          );

          final postProvider = Provider.of<PostProvider>(
            context,
            listen: false,
          );
          postProvider.addPost(newPost);

          AppSnackBar.show(context, "Post uploaded successfully!");


          await _clearDraft();
          Navigator.pop(context); // Navigate back
        } else {
          // Updating existing post

          // Ensure we send back the image URLs excluding the deleted ones
          final updatedPost = await FirebaseService.instance.updatePost(
            widget.post!.postId, // Post ID for the update
            _titleController.text.trim(),
            _contentController.text.trim(),
            selectedCategory,
            _imageUrls, // Use _imageUrls for the remote image URLs

          );

          // Update the post in the provider
          final postProvider = Provider.of<PostProvider>(
            context,
            listen: false,
          );
          postProvider.updatePost(updatedPost);


          AppSnackBar.show(context, "Post updated successfully!");

          await _clearDraft();
          Navigator.pop(context); // Navigate back
          Navigator.pop(context); // Navigate back

        }
      } catch (e) {
        AppSnackBar.show(context, 'Failed to upload post: $e');

      } finally {
        if (mounted) setState(() => _isLoading = false); // Stop loading
      }
    }
  }

  void _saveDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> imagePaths = _selectedImages.map((file) => file.path).toList();

    Map<String, dynamic> draft = {
      'title': _titleController.text,
      'content': _contentController.text,
      'category': selectedCategory,
      'images': imagePaths,
    };

    await prefs.setString('post_draft', jsonEncode(draft));
  }

  Future<void> _loadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('post_draft');
    if (jsonString != null) {
      Map<String, dynamic> draft = jsonDecode(jsonString);
      _titleController.text = draft['title'] ?? '';
      _contentController.text = draft['content'] ?? '';
      selectedCategory = draft['category'] ?? 'Events';

      if (draft['images'] != null) {
        List<String> imagePaths = List<String>.from(draft['images']);
        _selectedImages.clear();
        _selectedImages.addAll(imagePaths.map((path) => File(path)).toList());
      }

      setState(() {}); // Refresh UI
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    _shouldSaveDraft = false; // prevent saving again on dispose
    await prefs.remove('post_draft');
  }

  void _checkForDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Double check to prevent false positive
    final hasDraft = prefs.containsKey('post_draft');
    if (!hasDraft) return;

    final draft = jsonDecode(prefs.getString('post_draft')!);
    final imagePaths = List<String>.from(draft['images'] ?? []);
    final hasImage = imagePaths.isNotEmpty;
    final firstImage = hasImage ? File(imagePaths[0]) : null;

    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
              child: Stack(
                children: [
                  // Content of the dialog
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thumbnail
                      if (hasImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio:
                                4 /
                                3, // Set the aspect ratio you want (e.g., 16:9 or 4:3)
                            child: Image.file(
                              firstImage!,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      SizedBox(height: 16),
                      // Message
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continue creating post?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'We found an unsaved post draft. Would you like to continue editing it?',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await _clearDraft();
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text('No Need'),
                                ),
                                SizedBox(width: 6),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _loadDraft();
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF203980),
                                  ),
                                  child: Text(
                                    'Continue',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Buttons
                    ],
                  ),
                  // Close Button - Positioned at top-right corner
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 2),
                          ],
                        ),
                        child: Icon(Icons.close, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      );
    });
  }

  bool _hasContentToSave() {
    return _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty ||
        _selectedImages.isNotEmpty;
  }

  @override
  void dispose() {
    // Save draft when widget is disposed (when the page is popped)
    if (_shouldSaveDraft && _hasContentToSave()) {
      _saveDraft();
    }
    _titleController.dispose();
    _contentController.dispose();
    WidgetsBinding.instance.removeObserver(this); // Unregister as observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Detect app lifecycle changes and save draft when backgrounded or closed
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_shouldSaveDraft && _hasContentToSave()) {
        _saveDraft();
      }
    }
  }

  Widget _buildImagePreview() {
    return Row(
      children: [
        ...(_imageUrls.length == 1 && _imageUrls[0].isEmpty
            ? [] // if it's [""] just skip entirely
            : _imageUrls.map((imageUrl) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
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
                        _imageUrls.remove(imageUrl);
                        if (_imageUrls.isEmpty) {
                          _imageUrls = [""]; // Reset to default
                        }
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
                            offset: Offset(0, 2),
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
          );
        })),

        // Now handle the local images (files)
        ..._selectedImages.map((image) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
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
                            offset: Offset(0, 2),
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
          );
        }),
        // Add image picker button if less than 3 images
        if (_selectedImages.length + _imageUrls.length < 3)
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(),

              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter Title',
                  border: InputBorder.none, // Default no border
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title is required';
                  }

                  final wordCount = value.trim().split(RegExp(r'\s+')).length;
                  if (wordCount > 50) {
                    return 'Title must be 50 words or fewer';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter Content',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Content is required';
                  }

                  final wordCount = value.trim().split(RegExp(r'\s+')).length;
                  if (wordCount > 500) {
                    return 'Content must be 500 words or fewer';
                  }
                  return null;
                },
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
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF203980), // Match button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            widget.post == null ? "Post" : "Update",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
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
          color:
              selectedCategory == category
                  ? Color(0xFF203980)
                  : Colors.grey[200],
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


class WordLimitInputFormatter extends TextInputFormatter {
  final int maxWords;

  WordLimitInputFormatter(this.maxWords);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final words = newValue.text.trim().split(RegExp(r'\s+'));

    if (words.length > maxWords) {
      return oldValue;
    }

    return newValue;
  }
}

