import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class ARLoadingBox extends StatefulWidget {
  const ARLoadingBox({super.key});

  @override
  State<ARLoadingBox> createState() => _ARLoadingBoxState();
}

class _ARLoadingBoxState extends State<ARLoadingBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final String _text = 'Loading AR...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/videos/loading.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_text.length, (index) {
                    // Each letter has a wave offset based on index
                    final wave = sin(
                      (_controller.value * 2 * pi) - (index * 0.4),
                    );
                    final offset = wave * 4; // 4px wave height, adjust to taste

                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: Text(
                        _text[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
