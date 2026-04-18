import 'package:flutter/material.dart';

class ARLoadingBox extends StatelessWidget {
  const ARLoadingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text('Loading AR...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
