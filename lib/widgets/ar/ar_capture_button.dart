import 'package:flutter/material.dart';

class ARCaptureButton extends StatelessWidget {
  final VoidCallback onTap;

  const ARCaptureButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF9BE2C),
            ),
          ),
        ),
      ),
    );
  }
}
