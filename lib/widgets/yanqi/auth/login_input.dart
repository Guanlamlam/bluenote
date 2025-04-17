import 'package:flutter/material.dart';

class LoginInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;

  const LoginInput({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
    );
  }
}
