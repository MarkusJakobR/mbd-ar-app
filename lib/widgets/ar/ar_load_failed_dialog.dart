import 'package:flutter/material.dart';

class ARLoadFailedDialog extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const ARLoadFailedDialog({
    super.key,
    required this.onBack,
    required this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onBack,
    required VoidCallback onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ARLoadFailedDialog(onBack: onBack, onRetry: onRetry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Color(0xFFF9BE2C),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/no_wifi.png', // replace with your image path
              height: 150,
              width: 150,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'No Connection',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'This product could not be loaded. Please check your connection and try again when the network is stable.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Go Back button
              Expanded(
                child: GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Go Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Retry button
              Expanded(
                child: GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2A6D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Retry',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
