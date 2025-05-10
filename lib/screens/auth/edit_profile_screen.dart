import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bluenote/service/firebase_service.dart'; // Assuming this is where the uploadToCloudinary function is located

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _gender = 'Male'; // Default gender
  String _bio = ''; // Bio field
  String _profileImageUrl = ''; // Profile Image URL

  // TextEditing controllers
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _bioController = TextEditingController();

  // Gender options
  List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data when screen initializes
  }

  // Load user data from Firestore and FirebaseAuth
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _username = userData['username'] ?? '';
          _email = userData['email'] ?? '';
          _gender = userData['gender'] ?? 'Male';
          _bio = userData['bio'] ?? ''; // Set bio from Firestore
          _profileImageUrl = userData['profilePictureUrl'] ?? ''; // Profile picture URL

          // Set controllers with the fetched data
          _usernameController.text = _username;
          _emailController.text = _email;
          _bioController.text = _bio;
        });
      } catch (e) {
        print("Error loading user data: $e");
      }
    }
  }

  // Method to pick an image and upload to Cloudinary
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Picked file (Image)
      final imageFile = File(pickedFile.path); // Ensure we use a File object

      try {
        // Upload image to Cloudinary and get the URL
        String? uploadedImageUrl = await FirebaseService.instance.uploadToCloudinary(imageFile);

        if (uploadedImageUrl != null) {
          setState(() {
            _profileImageUrl = uploadedImageUrl;  // Update profileImageUrl with the Cloudinary URL
          });
          print("Image uploaded to Cloudinary: $uploadedImageUrl");
        }
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }

  // Save updated profile data to Firestore
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final String finalBio = _bio.isEmpty ? 'No bio available' : _bio; // Default bio if empty

        // Save profile data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': _username,
          'email': _email,
          'gender': _gender,
          'bio': finalBio,  // Save bio here
          'profilePictureUrl': _profileImageUrl,  // Save profile picture URL
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // Navigate back to the Profile screen
        Navigator.pop(context);  // This will go back to the previous screen (Profile screen)
      } catch (e) {
        print("Error updating profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                _saveProfile();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: GestureDetector(
                  onTap: _pickAndUploadImage, // Trigger image picker
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl) // Load profile image from URL
                        : const AssetImage('assets/images/default-profile.jpg') as ImageProvider, // Default image
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
                onChanged: (value) {
                  _username = value ?? '';
                },
              ),
              const SizedBox(height: 16),

              // Email Field (Read-Only, No Pen Icon)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // Make the email field read-only
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _gender = newValue ?? 'Male';
                  });
                },
                items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Bio Field
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _bio = value ?? '';
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
