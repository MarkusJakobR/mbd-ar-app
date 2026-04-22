import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import '../models/product.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/ar/ar_widgets.dart';
import 'dart:io';
import '../services/tutorial_prefs.dart';

class ARFurnitureMode extends StatefulWidget {
  final Product product;
  const ARFurnitureMode({super.key, required this.product});

  @override
  State<ARFurnitureMode> createState() => _ARFurnitureModeState();
}

class _ARFurnitureModeState extends State<ARFurnitureMode>
    with WidgetsBindingObserver {
  UnityWidgetController? _unityController;
  final GlobalKey _rotateCWKey = GlobalKey();
  final GlobalKey _rotateCCWKey = GlobalKey();
  final GlobalKey _lockKey = GlobalKey();
  final GlobalKey _deleteKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _hintKey = GlobalKey();
  bool _unityReady = false;
  bool _assetsReady = false;
  bool _isLeaving = false;

  bool get _isLoading => !_unityReady || !_assetsReady;

  bool _objectSelected = false;
  bool _isLocked = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkTutorial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
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

  Future<void> _checkTutorial() async {
    final hasSeen = await TutorialPrefs.hasSeenFurnitureTutorial();
    if (!hasSeen && mounted) {
      // Small delay so Unity has time to render first
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _showTutorial = true);
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

  void _post(String method, [String message = '']) {
    print('Flutter: Sending to Unity -> Method: $method, Message: $message');
    _unityController?.postMessage('ARManager', method, message);
  }

  Future<void> _onBack() async {
    setState(() => _isLeaving = true);
    _post('ResetScene');
    await Future.delayed(const Duration(milliseconds: 150));
    _stopCamera();
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) Navigator.pop(context);
  }

  void onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
    print('Unity loaded for ${widget.product.name} (Furniture Mode)');

    _startCamera();

    // Ensure we're in furniture mode
    _post('SwitchToFurnitureMode');

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
      case 'AssetsReady':
        if (mounted) setState(() => _assetsReady = true);
        break;
      case 'AssetsFailed':
        _showLoadFailedDialog();
        break;
      case 'ObjectSelected':
        if (mounted) {
          setState(() {
            _objectSelected = true;
            _isLocked = false;
          });
        }
        break;
      case 'ObjectDeselected':
        if (mounted) {
          setState(() {
            _objectSelected = false;
            _isLocked = false;
          });
        }
        break;
      default:
        if (msg.startsWith('ScreenshotSaved:')) {
          final path = msg.replaceFirst('ScreenshotSaved:', '');
          _handleScreenshotSaved(path);
        } else if (msg.startsWith('LockState:')) {
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

  void _showLoadFailedDialog() {
    if (!mounted) return;
    ARLoadFailedDialog.show(
      context,
      onBack: () {
        Navigator.pop(context); // close dialog
        Navigator.pop(context); // go back
      },
      onRetry: () {
        Navigator.pop(context);
        _sendProductToUnity();
      },
    );
  }

  List<TutorialStep> _buildTutorialSteps() {
    return [
      TutorialStep(
        title: 'Place Your Furniture',
        description:
            'Tap anywhere on a detected floor plane to place the furniture.',
        targetKey: _hintKey,
        radius: 120,
      ),
      TutorialStep(
        title: 'Rotate',
        description:
            'Hold the rotate buttons to spin the furniture, or use two fingers to twist it.',
        targetKey: _rotateCWKey,
        secondTargetKey: _rotateCCWKey,
      ),
      TutorialStep(
        title: 'Lock in Place',
        description:
            'Lock the furniture to prevent accidental movement or rotation.',
        targetKey: _lockKey,
      ),
      TutorialStep(
        title: 'Delete',
        description: 'Remove the currently selected furniture from the scene.',
        targetKey: _deleteKey,
      ),
      TutorialStep(
        title: 'More Options',
        description:
            'Duplicate furniture, reset the entire scene, or take a screenshot from the menu.',
        targetKey: _menuKey,
      ),
      TutorialStep(
        title: "You're All Set!",
        description: 'Start exploring how your furniture looks in your space.',
        showSpotlight: false,
      ),
    ];
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
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            UnityWidget(
              onUnityCreated: onUnityCreated,
              onUnityMessage: onUnityMessage,
              fullscreen: false,
            ),

            if (_unityReady && !_objectSelected && !_isLoading)
              Positioned(
                top: 200,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    key: _hintKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tap to place objects',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // Furniture mode controls - only when object selected
            if ((_objectSelected && _unityReady) || _showTutorial)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height / 2 - 50,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ARHoldButton(
                        key: _rotateCWKey,
                        onDown: () => _post('RotateClockwise'),
                        onUp: () => _post('StopRotating'),
                        icon: Icons.rotate_right,
                      ),
                      const SizedBox(height: 12),
                      ARHoldButton(
                        key: _rotateCCWKey,
                        onDown: () => _post('RotateCounter'),
                        onUp: () => _post('StopRotating'),
                        icon: Icons.rotate_left,
                      ),
                      const SizedBox(height: 12),
                      ARIconButton(
                        key: _lockKey,
                        onTap: () {
                          _post('ToggleLock');
                          setState(() => _isLocked = !_isLocked);
                        },
                        icon: _isLocked ? Icons.lock : Icons.lock_open,
                      ),
                      const SizedBox(height: 12),
                      ARIconButton(
                        key: _deleteKey,
                        onTap: () => _post('DeleteSelected'),
                        icon: Icons.delete_outline,
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLeaving) Container(color: Colors.black),

            ARTopBar(
              menuKey: _menuKey,
              onBack: _onBack,
              title: widget.product.name,
              subtitle: '₱${widget.product.price.toStringAsFixed(2)}',
              onMenuSelected: (value) async {
                switch (value) {
                  case 'reset':
                    _post('ResetScene');
                    break;
                  case 'duplicate':
                    _post('DuplicateSelected');
                    break;
                  case 'screenshot':
                    _post('TakeScreenshot');
                    break;
                  case 'help':
                    await TutorialPrefs.resetFurnitureTutorial();
                    setState(() => _showTutorial = true);
                    break;
                }
              },
              menuItems: [
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Reset'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'screenshot',
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Screenshot'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Duplicate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'help',
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Help'),
                    ],
                  ),
                ),
              ],
            ),
            if (_showTutorial && !_isLoading)
              ARTutorial(
                steps: _buildTutorialSteps(),
                onComplete: () async {
                  await TutorialPrefs.markFurnitureTutorialSeen();
                  if (mounted) setState(() => _showTutorial = false);
                },
              ),
            if (_isLoading) ARLoadingBox(),
          ],
        ),
      ),
    );
  }
}
