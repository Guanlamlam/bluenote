import 'package:flutter/material.dart';
import 'package:bluenote/widgets/yanqi/auth/login_form.dart';  // Import LoginForm

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Prevent keyboard overflow
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to previous screen
          },
        ),
      ),
      body: SafeArea(
        child: LoginForm(), // Your login form widget
      ),
    );
  }
}
