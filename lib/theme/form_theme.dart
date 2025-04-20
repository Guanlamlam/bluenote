import 'package:flutter/material.dart';

class FormTheme {
  // Page padding used in all forms
  static const pagePadding = EdgeInsets.all(24.0);

  // Titles like "Sign Up"
  static const headerStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  // Subtexts like "Please fill the following"
  static const subTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  // Main color used for buttons
  static const primaryColor = Color(0xFF203980);

  // Custom input decoration
  static InputDecoration inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText.isNotEmpty ? hintText : null,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      // ✅ Bolder border (normal)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.grey,   // optional: default color
          width: 1.8,           // ✅ make it bold
        ),
      ),

      // ✅ Bolder border when focused
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2.2,           // ✅ extra bold when active
        ),
      ),
    );
  }


  // Optional: A reusable primary button style
  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}
