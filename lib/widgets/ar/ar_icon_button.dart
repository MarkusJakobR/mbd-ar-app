import 'package:flutter/material.dart';
import 'ar_button_container.dart';

class ARIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color? color;
  final String? tooltip;

  const ARIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: ARButtonContainer(
          isActive: isActive,
          child: Icon(icon, color: color ?? Colors.white, size: 26),
        ),
      ),
    );
  }
}
