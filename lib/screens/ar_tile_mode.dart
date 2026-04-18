import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import '../models/product.dart';
import '../widgets/ar/ar_widgets.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ARTileMode extends StatefulWidget {
  final Product product;
  const ARTileMode({super.key, required this.product});

  @override
  State<ARTileMode> createState() => _ARTileModeState();
}

class _ARTileModeState extends State<ARTileMode> with WidgetsBindingObserver {
  UnityWidgetController? _unityController;
  bool _unityReady = false;
  int _minTileCount = 0;
  int _maxTileCount = 0;
  int _pointCount = 0;
  double _minTotalCost = 0;
  double _maxTotalCost = 0;
  double _totalArea = 0.0;
  bool _tileExist = false;
  bool _markersVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _stopCamera();
    _post('ClearAll');
    setState(() {
      _minTileCount = 0;
      _maxTileCount = 0;
      _minTotalCost = 0.0;
      _maxTotalCost = 0.0;
      _totalArea = 0.0;
      _tileExist = false;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.pop(context);
  }

  void onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
    print('Unity loaded for ${widget.product.name} (Tile Mode)');

    _startCamera();

    // Ensure we're in tile mode
    _post('SwitchToTileMode');

    Future.delayed(const Duration(seconds: 5), () {
      if (!_unityReady && mounted) {
        print('Unity ready timeout — sending tile data anyway');
        setState(() => _unityReady = true);
        _sendTileToUnity();
      }
    });
  }

  void onUnityMessage(dynamic message) {
    final msg = message.toString();
    print('Message from Unity: $msg');

    if (msg.startsWith('ScreenshotSaved:')) {
      final path = msg.replaceFirst('ScreenshotSaved:', '');
      _handleScreenshotSaved(path);
      return;
    }

    switch (msg) {
      case 'OnUnityReady':
        if (!_unityReady && mounted) {
          setState(() => _unityReady = true);
          _sendTileToUnity();
        }
        break;
      default:
        if (msg.startsWith('TileCount:')) {
          final parts = msg.replaceFirst('TileCount:', '').split('|');
          final minCount = int.tryParse(parts[0]) ?? 0;
          final maxCount = int.tryParse(parts[1]) ?? 0;
          final area = double.parse(parts[2]);
          final minCost = double.parse(parts[3]);
          final maxCost = double.parse(parts[4]);
          if (mounted) {
            setState(() {
              _minTileCount = minCount;
              _maxTileCount = maxCount;
              _minTotalCost = minCost;
              _maxTotalCost = maxCost;
              _totalArea = area;
              _tileExist = true;
            });
          }
        }
        break;
    }
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

  void _sendTileToUnity() {
    if (_unityController == null) return;
    final message = jsonEncode(widget.product.toUnityMessage());
    print('Sending tile to Unity: $message');
    _unityController!.postMessage('ARManager', 'OnTileSelected', message);
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

            ARTopBar(
              onBack: _onBack,
              title: widget.product.name,
              subtitle: '₱${widget.product.price.toStringAsFixed(2)}',
              onMenuSelected: (value) {
                switch (value) {
                  case 'reset':
                    _post('ClearAll');
                    setState(() {
                      _minTileCount = 0;
                      _maxTileCount = 0;
                      _minTotalCost = 0.0;
                      _maxTotalCost = 0.0;
                      _totalArea = 0.0;
                      _tileExist = false;
                    });
                    break;
                  case 'screenshot':
                    _post('TakeScreenshotTile');
                    break;
                  case 'help':
                    // show tutorial later
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
                if (_tileExist == true)
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

            if (!_unityReady) ARLoadingBox(),

            if (_unityReady && _tileExist == true)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height / 2 - 50,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ARHoldButton(
                        icon: Icons.rotate_right,
                        onDown: () => _post('RotateClockwiseTile'),
                        onUp: () => _post('StopRotatingTile'),
                      ),
                      const SizedBox(height: 12),
                      ARHoldButton(
                        icon: Icons.rotate_left,
                        onDown: () => _post('RotateCounterTile'),
                        onUp: () => _post('StopRotatingTile'),
                      ),
                      const SizedBox(height: 12),
                      ARIconButton(
                        icon: _markersVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        onTap: () {
                          _post('HideMarkers');
                          setState(() => _markersVisible = !_markersVisible);
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // Tile mode instruction overlay
            if (_unityReady && _pointCount == 0)
              Positioned(
                top: 200,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Click the button below to add points',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            if (_unityReady && _tileExist == false)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Capture button — centered
                    ARCaptureButton(
                      onTap: () {
                        _post('ConfirmCrosshairPoint');
                        setState(() => _pointCount += 1);
                      },
                    ),
                    // Undo button — offset to the right of center
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 + 80,
                      child: ARIconButton(
                        icon: Icons.undo_outlined,
                        onTap: () => _post('UndoTilePoint'),
                      ),
                    ),
                  ],
                ),
              ),

            // Tile count display
            if (_unityReady && _tileExist == true)
              ARTileInfoCard(
                productName: widget.product.name,
                minTileCount: _minTileCount,
                maxTileCount: _maxTileCount,
                minTotalCost: _minTotalCost,
                maxTotalCost: _maxTotalCost,
                totalArea: _totalArea,
              ),
          ],
        ),
      ),
    );
  }
}
