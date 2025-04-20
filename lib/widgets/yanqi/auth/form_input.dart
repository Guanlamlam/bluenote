import 'package:flutter/material.dart';
import 'package:bluenote/theme/form_theme.dart';

class FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;

  const FormInput({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, // ✅ visible label above the field
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14), // ✅ smaller text
          decoration: FormTheme.inputDecoration(''), // ✅ No labelText inside the box
        ),
      ],
    );
  }
}
