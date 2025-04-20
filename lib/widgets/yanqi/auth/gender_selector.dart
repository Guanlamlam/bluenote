import 'package:flutter/material.dart';
import 'package:bluenote/theme/form_theme.dart';

class GenderSelector extends StatelessWidget {
  final String? selected;
  final void Function(String?) onChanged;

  const GenderSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: FormTheme.inputDecoration('Gender'),
      items: ['Male', 'Female', 'Other'].map((gender) {
        return DropdownMenuItem(value: gender, child: Text(gender));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
