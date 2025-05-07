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
//added by lam!!!


class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get userId (lam)!!
      String userId = userCredential.user!.uid;
      saveTokenToDatabase(userId);

      // Get username from Firestore and cache it
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;

        await cacheUserData(
          userId: userId,
          username: userData['username'] ?? 'Unknown',
          profilePictureUrl: userData['profilePictureUrl'] ?? '',
        );
      }


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
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

          // Password input + Forgot password
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoginInput(controller: _passwordController, label: 'Password', obscure: true),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password screen
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
