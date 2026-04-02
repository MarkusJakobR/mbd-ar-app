import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FurnitureSplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const FurnitureSplashScreen({super.key, required this.onFinish});

  @override
  State<FurnitureSplashScreen> createState() => _FurnitureSplashScreenState();
}

class _FurnitureSplashScreenState extends State<FurnitureSplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Assuming you saved your Manim export in assets/videos/splash.mp4
    _controller =
        VideoPlayerController.asset(
            'assets/videos/splash.mp4',
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..initialize().then((_) {
            setState(() {});
            _controller.play();
            _controller.setLooping(true);
          });

    // Check if initialization is complete every few seconds,
    // or you can set a timer to ensure the user sees the animation.
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9BE2C), // Matches your HomePage
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const SizedBox.shrink(), // Keep it clean while loading asset
      ),
    );
  }
}
