import 'package:flutter/material.dart';
import 'package:bluenote/theme/form_theme.dart'; // Import your form theme

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LoginButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Makes the button take full width
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: FormTheme.primaryColor,  // Use primaryColor from FormTheme
          foregroundColor: Colors.white,  // Text color (white)
          padding: const EdgeInsets.symmetric(vertical: 16),  // Padding from FormTheme
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),  // Rounded corners for the button
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,  // Bold text style
            fontSize: 16,  // Font size for button text
          ),
        ),
        child: const Text('Login'),  // Text displayed on the button
      ),
    );
  }
}
