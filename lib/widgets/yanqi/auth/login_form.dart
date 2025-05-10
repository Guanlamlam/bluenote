import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bluenote/widgets/yanqi/auth/login_input.dart';
import 'package:bluenote/widgets/yanqi/auth/login_button.dart';
import 'package:bluenote/theme/form_theme.dart';
import 'package:bluenote/screens/auth/register_screen.dart';
import 'package:bluenote/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> cacheUserData({
  required String userId,
  required String username,
  required String profilePictureUrl,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('cached_user_id', userId);
  await prefs.setString('cached_username', username);
  await prefs.setString('cached_profile_picture', profilePictureUrl);
}

Future<Map<String, String?>> getCachedUserData() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'userId': prefs.getString('cached_user_id'),
    'username': prefs.getString('cached_username'),
    'profilePictureUrl': prefs.getString('cached_profile_picture'),
  };
}


class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

//added by lam!!!
void saveTokenToDatabase(String userId) async {
  String? token = await FirebaseMessaging.instance.getToken(); //one device one token only

  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = ''; // Variable to store error message

  // Function to handle login
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Attempt to sign in the user with Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If successful, save user data and navigate to HomeScreen
      String userId = userCredential.user!.uid;
      saveTokenToDatabase(userId);

      // Fetch and cache user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;

        await cacheUserData(
          userId: userId,
          username: userData['username'] ?? 'Unknown',
          profilePictureUrl: userData['profilePictureUrl'] ?? '',
        );
      }

      // Navigate to HomeScreen on successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );

    } catch (e) {
      // Show a custom error message for login failures
      setState(() {
        _errorMessage = 'Incorrect username or password. Please try again.';  // Custom error message
      });
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

              const Text('Sign In', style: FormTheme.headerStyle),
              const SizedBox(height: 4),
              const Text('Enter your credentials', style: FormTheme.subTextStyle),
              const SizedBox(height: 20),

              // Email input
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: LoginInput(controller: _emailController, label: 'Email Address'),
              ),
              const SizedBox(height: 12),

              // Password input
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: LoginInput(controller: _passwordController, label: 'Password', obscure: true),
              ),
              const SizedBox(height: 20),

              // Error message display
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 10),

              // Login button
              LoginButton(onPressed: _signIn),
              const SizedBox(height: 20),

              // Sign up text centered
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: 'Do not have an Account? ',
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            ),
        );
    }
}