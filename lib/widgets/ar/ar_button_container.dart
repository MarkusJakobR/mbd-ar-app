import 'package:flutter/material.dart';

class ARButtonContainer extends StatelessWidget {
  final Widget child;
  final bool isActive;

  const ARButtonContainer({
    super.key,
    required this.child,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2C2A6D) : Colors.black26,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(child: child),
    );
  }
}
