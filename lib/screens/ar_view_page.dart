import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import '../models/product.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ARViewPage extends StatefulWidget {
  final Product product;
  const ARViewPage({super.key, required this.product});

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> with WidgetsBindingObserver {
  UnityWidgetController? _unityController;
  bool _unityReady = false;
  bool _objectSelected = false;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera(); // just stop camera, don't dispose Unity
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _stopCamera();
        break;
      case AppLifecycleState.resumed:
        if (mounted) _startCamera();
        break;
      default:
        break;
    }
  }

  void _startCamera() {
    _unityController?.postMessage('ARManager', 'StartCamera', '');
    print('Camera started');
  }

  void _stopCamera() {
    _unityController?.postMessage('ARManager', 'StopCamera', '');
    print('Camera stopped');
  }

  // Single helper for all Unity messages
  void _post(String method, [String message = '']) {
    print('Flutter: Sending to Unity -> Method: $method, Message: $message');
    _unityController?.postMessage('ARManager', method, message);
  }

  Future<void> _onBack() async {
    _stopCamera();
    // Small delay so Unity processes StopCamera before we leave
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.pop(context);
  }

  void onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
    print('Unity loaded for ${widget.product.name}');

    // Start camera immediately when Unity widget is created
    _startCamera();

    // Fallback timer in case OnUnityReady never arrives
    Future.delayed(const Duration(seconds: 5), () {
      if (!_unityReady && mounted) {
        print('Unity ready timeout — sending product anyway');
        setState(() => _unityReady = true);
        _sendProductToUnity();
      }
    });
  }

  void onUnityMessage(dynamic message) {
    final msg = message.toString();
    print('Message from Unity: $msg');

    switch (msg) {
      case 'OnUnityReady':
        if (!_unityReady && mounted) {
          setState(() => _unityReady = true);
          _sendProductToUnity();
        }
        break;
      case 'ObjectSelected':
        if (mounted) {
          setState(() => _objectSelected = true);
          _isLocked = false;
        }
        break;
      case 'ObjectDeselected':
        if (mounted)
          setState(() {
            _objectSelected = false;
            _isLocked = false;
          });
        break;
      default:
        if (msg.startsWith('ScreenshotSaved:')) {
          final path = msg.replaceFirst('ScreenshotSaved:', '');
          _handleScreenshotSaved(path);
        } else if (msg.startsWith('LockState:')) {
          // Handle lock state message from Unity
          final isLocked = msg.replaceFirst('LockState:', '') == 'true';
          if (mounted) setState(() => _isLocked = isLocked);
        }
        break;
    }
  }

  void _sendProductToUnity() {
    if (_unityController == null) return;
    final message = jsonEncode(widget.product.toUnityMessage());
    print('Sending to Unity: $message');
    _unityController!.postMessage('ARManager', 'OnProductSelected', message);
    print('Product sent to Unity: ${widget.product.name}');
  }

  Future<void> _handleScreenshotSaved(String path) async {
    try {
      print('Screenshot path received: $path');

      // Request permission FIRST
      if (Platform.isIOS) {
        var status = await Permission.photosAddOnly.status;
        print('Current permission status: $status');

        if (!status.isGranted) {
          print('Requesting photo permission...');
          status = await Permission.photosAddOnly.request();
          print('Permission result: $status');
        }

        if (status.isDenied ||
            status.isPermanentlyDenied ||
            status.isRestricted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Photo permission denied. Enable in Settings.',
                ),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

      // Check if file exists
      final File imageFile = File(path);
      print('File exists: ${await imageFile.exists()}');

      if (await imageFile.exists()) {
        print('Saving to gallery...');
        final result = await ImageGallerySaver.saveFile(
          path,
          isReturnPathOfIOS: true,
        );
        print('Save result: $result');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result != null && result['isSuccess'] == true
                    ? 'Screenshot saved to Photos'
                    : 'Failed to save screenshot',
              ),
            ),
          );
        }
      } else {
        print('File does not exist at path: $path');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Screenshot file not found')),
          );
        }
      }
    } catch (e) {
      print('Error saving screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _stopCamera();
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.product.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBack,
          ),
        ),
        body: Stack(
          children: [
            UnityWidget(
              onUnityCreated: onUnityCreated,
              onUnityMessage: onUnityMessage,
              fullscreen: false,
            ),

            if (!_unityReady)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Loading AR...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: 16,
              top: 32,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconButton(
                      icon: Icons.refresh,
                      onTap: () => _post('ResetScene'),
                      tooltip: 'Reset',
                    ),
                    const SizedBox(height: 12),
                    if (_objectSelected)
                      _buildIconButton(
                        icon: Icons.copy,
                        onTap: () => _post('DuplicateSelected'),
                        tooltip: 'Duplicate',
                      ),
                    const SizedBox(height: 12),
                    _buildIconButton(
                      icon: Icons.help_outline,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Help: Tap to place, drag to move, pinch to rotate',
                            ),
                          ),
                        );
                      },
                      tooltip: 'Help',
                    ),
                  ],
                ),
              ),
            ),

            // Right side buttons — only when object selected
            if (_objectSelected && _unityReady)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHoldButton(
                        icon: Icons.rotate_right,
                        onDown: () => _post('RotateClockwise'),
                        onUp: () => _post('StopRotating'),
                        tooltip: 'Rotate right',
                      ),
                      const SizedBox(height: 12),
                      _buildHoldButton(
                        icon: Icons.rotate_left,
                        onDown: () => _post('RotateCounter'),
                        onUp: () => _post('StopRotating'),
                        tooltip: 'Rotate left',
                      ),
                      const SizedBox(height: 12),
                      _buildIconButton(
                        icon: _isLocked ? Icons.lock : Icons.lock_open,
                        onTap: () {
                          _post('ToggleLock');
                          setState(() => _isLocked = !_isLocked);
                        },
                        isActive: _isLocked,
                        tooltip: _isLocked ? 'Unlock' : 'Lock',
                      ),
                      const SizedBox(height: 12),
                      _buildIconButton(
                        icon: Icons.delete_outline,
                        onTap: () => _post('DeleteSelected'),
                        color: Colors.red.shade400,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ),
            // Screenshot always visible when Unity is ready
            if (_unityReady)
              Positioned(
                right: 16,
                bottom: 32,
                child: _buildIconButton(
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _post('TakeScreenshot'),
                  tooltip: 'Screenshot',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldButton({
    required IconData icon,
    required VoidCallback onDown,
    required VoidCallback onUp,
    String? tooltip,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        print('Flutter: Button pressed - $tooltip');
        onDown();
      },
      onTapUp: (_) {
        print('Flutter: Button released - $tooltip');
        onUp();
      },
      onTapCancel: () {
        print('Flutter: Button cancelled - $tooltip');
        onUp();
      },
      child: _buttonContainer(
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: _buttonContainer(
          isActive: isActive,
          child: Icon(
            icon,
            color: color ?? (isActive ? Colors.white : Colors.black87),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buttonContainer({required Widget child, bool isActive = false}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2C2A6D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
