import 'package:flutter/material.dart';
import 'package:bluenote/screens/auth/edit_profile_screen.dart'; // Import the EditProfileScreen

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to EditProfileScreen when the button is pressed
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfileScreen()), // Navigate to EditProfileScreen
        );
      },
      child: const Text('Edit Profile'),
    );
  }
}
