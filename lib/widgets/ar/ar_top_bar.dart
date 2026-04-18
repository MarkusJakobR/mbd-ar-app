import 'package:flutter/material.dart';
import 'ar_icon_button.dart';
import 'ar_button_container.dart';

class ARTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final List<PopupMenuEntry<String>> menuItems;
  final void Function(String) onMenuSelected;

  const ARTopBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    required this.menuItems,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ARIconButton(icon: Icons.arrow_back, onTap: onBack),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              ARButtonContainer(
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: onMenuSelected,
                  itemBuilder: (context) => menuItems,
                  padding: EdgeInsets
                      .zero, // removes default padding so it fits the container
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
