import 'package:flutter/material.dart';
import 'dart:ui';

class TutorialStep {
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final GlobalKey? secondTargetKey;
  final double radius;
  final bool showSpotlight;

  const TutorialStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.secondTargetKey,
    this.radius = 40,
    this.showSpotlight = true,
  });
}

class ARFurnitureTutorial extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;

  const ARFurnitureTutorial({
    super.key,
    required this.steps,
    required this.onComplete,
  });

  @override
  State<ARFurnitureTutorial> createState() => _ARFurnitureTutorialState();
}

class _ARFurnitureTutorialState extends State<ARFurnitureTutorial>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  Offset _spotlightCenter = Offset.zero;
  double _spotlightRadius = 60;
  late AnimationController _animController;
  late Animation<Offset> _positionAnimation;
  Offset _previousCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _positionAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );

    // Get first spotlight position after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSpotlight(0, animate: false);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Offset _getKeyPosition(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return _screenCenter();
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return Offset(position.dx + size.width / 2, position.dy + size.height / 2);
  }

  Offset _screenCenter() {
    final size = MediaQuery.of(context).size;
    return Offset(size.width / 2, size.height / 2);
  }

  void _updateSpotlight(int stepIndex, {bool animate = true}) {
    final step = widget.steps[stepIndex];
    final newCenter = step.targetKey != null
        ? _getKeyPosition(step.targetKey!)
        : _screenCenter();

    if (animate) {
      _positionAnimation = Tween<Offset>(begin: _previousCenter, end: newCenter)
          .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
          );
      _animController.forward(from: 0);
    }

    setState(() {
      _previousCenter = newCenter;
      _spotlightCenter = newCenter;
    });
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
      _updateSpotlight(_currentStep);
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _updateSpotlight(_currentStep);
    }
  }

  bool get _isLastStep => _currentStep == widget.steps.length - 1;
  bool get _isSpotlightInLowerHalf =>
      _spotlightCenter.dy > MediaQuery.of(context).size.height / 2;

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];

    return AnimatedBuilder(
      animation: _positionAnimation,
      builder: (context, child) {
        final animatedCenter = _animController.isAnimating
            ? _positionAnimation.value
            : _spotlightCenter;

        return Stack(
          children: [
            // Dark overlay with spotlight cutout
            if (step.showSpotlight)
              CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _SpotlightPainter(
                  center: animatedCenter,
                  secondCenter: step.secondTargetKey != null
                      ? _getKeyPosition(step.secondTargetKey!)
                      : null,
                  radius: step.radius,
                ),
              )
            else
              Container(color: Colors.black.withOpacity(0.75)),

            // Block all touches except navigation
            Positioned.fill(
              child: GestureDetector(
                onTap: () {}, // absorbs taps
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

            // Skip button
            Positioned(
              top: 64,
              left: 16,
              child: SafeArea(
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ),

            // Text — above or below spotlight
            _buildStepText(step, animatedCenter),

            // Navigation row at bottom
            Positioned(
              bottom: 48,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _currentStep > 0
                      ? IconButton(
                          onPressed: _previousStep,
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        )
                      : const SizedBox(width: 48),

                  // Step dots
                  Row(
                    children: List.generate(
                      widget.steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentStep == index ? 16 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentStep == index
                              ? const Color(0xFF2C2A6D)
                              : Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Done button
                  IconButton(
                    onPressed: _nextStep,
                    icon: Icon(
                      _isLastStep ? Icons.check : Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepText(TutorialStep step, Offset center) {
    final isLower = center.dy > MediaQuery.of(context).size.height / 2;
    final textOffset = _spotlightRadius + 24;

    return Positioned(
      top: !_isSpotlightInLowerHalf ? center.dy + textOffset : null,
      bottom: _isSpotlightInLowerHalf
          ? MediaQuery.of(context).size.height - center.dy + textOffset
          : null,
      left: 32,
      right: 32,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2A6D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              step.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final Offset? secondCenter;
  final double radius;

  _SpotlightPainter({
    required this.center,
    this.secondCenter,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.75);

    // Combine both circles into one united shape first
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    if (secondCenter != null) {
      final secondCircle = Path()
        ..addOval(Rect.fromCircle(center: secondCenter!, radius: radius));

      // Union merges them into one shape with no overlap issues
      final combined = Path.combine(
        PathOperation.union,
        circlePath,
        secondCircle,
      );

      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addPath(combined, Offset.zero);

      canvas.drawPath(path, paint);
    } else {
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(Rect.fromCircle(center: center, radius: radius));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.center != center ||
      old.secondCenter != secondCenter ||
      old.radius != radius;
}
