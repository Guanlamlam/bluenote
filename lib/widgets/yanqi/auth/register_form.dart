import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bluenote/widgets/yanqi/auth/form_input.dart';
import 'package:bluenote/widgets/yanqi/auth/register_button.dart';
import 'package:bluenote/theme/form_theme.dart';
import 'package:bluenote/widgets/yanqi/auth/gender_selector.dart';

import '../../../screens/auth/login_screen.dart';  // Correct import for LoginScreen

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _selectedGender;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to register the user
  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      // Check if the email is already in use
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(_emailController.text);

      if (signInMethods.isNotEmpty) {
        // The email is already in use
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The email address is already in use by another account.')),
        );
        return;
      }

      // Firebase authentication logic
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Save additional user data to Firestore
      FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'username': _usernameController.text,  // Storing username
        'email': _emailController.text,         // Storing email
        'gender': _selectedGender,             // Storing gender
        'createdAt': FieldValue.serverTimestamp(),  // Storing created timestamp
      });

      // Navigate to the LoginScreen after successful registration using Navigator.push
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),  // Navigate to LoginScreen
      );

    } catch (e) {
      // Handle other errors (e.g., weak password, email already in use, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: FormTheme.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Title without back button
          const Text('Sign up', style: FormTheme.headerStyle),
          const SizedBox(height: 4),
          const Text('Please fill the following', style: FormTheme.subTextStyle),
          const SizedBox(height: 20),

          // Username Input
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FormInput(controller: _usernameController, label: 'Username'),
          ),
          const SizedBox(height: 12),

          // Email Input
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FormInput(controller: _emailController, label: 'Email Address'),
          ),
          const SizedBox(height: 12),

          // Gender Dropdown (Assumed GenderSelector widget)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: GenderSelector(
              selected: _selectedGender,
              onChanged: (val) => setState(() => _selectedGender = val),
            ),
          ),
          const SizedBox(height: 12),

          // Password Input
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FormInput(
              controller: _passwordController,
              label: 'Password',
              obscure: true,
            ),
          ),
          const SizedBox(height: 12),

          // Confirm Password Input
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FormInput(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscure: true,
            ),
          ),
          const SizedBox(height: 24),

          // Register Button
          RegisterButton(onPressed: _register),  // Using _register function here
          const SizedBox(height: 16),

          // Sign In Text
          Center(
            child: GestureDetector(
              onTap: () {
                // Navigate to LoginScreen when tapped using Navigator.push
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),  // Navigate to LoginScreen
                );
              },
              child: const Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
