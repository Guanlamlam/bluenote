import 'package:flutter/material.dart';
import 'package:bluenote/theme/form_theme.dart';  // Import your theme for styling

class RegisterButton extends StatelessWidget {
  // Define a callback that will be passed to the button to handle the onPressed action
  final VoidCallback onPressed;

  // Constructor to accept onPressed callback
  const RegisterButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,  // Makes the button take full width
      child: ElevatedButton(
        onPressed: onPressed,  // Calls the provided onPressed function when the button is pressed
        style: ElevatedButton.styleFrom(
          backgroundColor: FormTheme.primaryColor,   // Button background color from theme
          foregroundColor: Colors.white,             // Text color (white)
          padding: const EdgeInsets.symmetric(vertical: 16),  // Button's vertical padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),  // Rounded corners
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,  // Font weight (bold)
            fontSize: 16,                 // Font size
          ),
        ),
        child: const Text('Next'),  // Text displayed on the button
      ),
    );
  }
}
