import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String _profileImageUrl = ''; // Profile Image URL (Not used since no Firebase Storage)

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
          _profileImageUrl = userData['profilePictureUrl'] ?? ''; // This is not used, as we are not using Firebase Storage

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

  // Save updated profile data to Firestore
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Debugging: Check what the bio value is before updating
        print("Saving bio: $_bio");

        final String finalBio = _bio.isEmpty ? 'No bio available' : _bio; // Default bio if empty

        // Save profile data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': _username,
          'email': _email,
          'gender': _gender,
          'bio': finalBio,  // Save bio here
        });

        // Debugging: Confirm the bio has been saved
        print("Bio saved to Firestore: $finalBio");

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // Navigate back to the Profile screen
        Navigator.pop(context);  // This will go back to the previous screen (Profile screen)
      } catch (e) {
        // Debugging: Log errors when updating Firestore
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
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImageUrl.isNotEmpty
                      ? NetworkImage(_profileImageUrl) // Load profile image from URL
                      : const AssetImage('assets/images/default-profile.jpg') as ImageProvider, // Default image
                ),
              ),
              const SizedBox(height: 16),
              // Change Profile Picture Button (if you decide to add later)
              // Center(
              //   child: TextButton(
              //     onPressed: _pickProfileImage,
              //     child: const Text('Change Profile Picture'),
              //   ),
              // ),
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
                onSaved: (value) {
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
                onSaved: (value) {
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
