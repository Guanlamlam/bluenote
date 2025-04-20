import 'package:flutter/material.dart';

class ForgotPassword extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Forgot password action
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
