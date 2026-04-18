import 'package:flutter/material.dart';
import 'ar_button_container.dart';

class ARHoldButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const ARHoldButton({
    super.key,
    required this.icon,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: ARButtonContainer(
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
