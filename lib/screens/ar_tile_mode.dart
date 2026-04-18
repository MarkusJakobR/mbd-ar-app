import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import '../models/product.dart';
import '../widgets/ar/ar_widgets.dart';

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
                  case 'help':
                    // show tutorial later
                    break;
                }
              },
              menuItems: const [
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
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ARCaptureButton(
                        onTap: () => {
                          _post('ConfirmCrosshairPoint'),
                          _pointCount += 1,
                        },
                      ),
                      const SizedBox(width: 12),
                      ARIconButton(
                        icon: Icons.undo_outlined,
                        onTap: () => _post('UndoTilePoint'),
                      ),
                    ],
                  ),
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
