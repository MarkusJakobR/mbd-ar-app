import 'package:flutter/material.dart';

class ChecklistFilter extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const ChecklistFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return CheckboxListTile(
          title: Text(option),
          value: isSelected,
          onChanged: (checked) {
            final updated = Set<String>.from(selected);
            if (checked == true) {
              updated.add(option);
            } else {
              updated.remove(option);
            }
            onChanged(updated);
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xFF2C2A6D),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}
