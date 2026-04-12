import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import '../models/product.dart';
import 'dart:io';

class ARTileMode extends StatefulWidget {
  final Product product;
  const ARTileMode({super.key, required this.product});

  @override
  State<ARTileMode> createState() => _ARTileModeState();
}

class _ARTileModeState extends State<ARTileMode> with WidgetsBindingObserver {
  UnityWidgetController? _unityController;
  bool _unityReady = false;
  int _tileCount = 0;
  double _totalArea = 0.0;
  String? _selectedPlaneId;

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
          final count = int.tryParse(parts[0]) ?? 0;
          final tileName = parts.length > 1 ? parts[1] : widget.product.name;
          if (mounted) {
            setState(() => _tileCount = count);
          }
        } else if (msg.startsWith('TileArea:')) {
          final area =
              double.tryParse(msg.replaceFirst('TileArea:', '')) ?? 0.0;
          if (mounted) {
            setState(() => _totalArea = area);
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
        appBar: AppBar(
          title: Text(widget.product.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBack,
          ),
          actions: [
            _buildIconButton(
              icon: Icons.refresh,
              onTap: () {
                _post('ClearAll');
                setState(() {
                  _tileCount = 0;
                  _totalArea = 0.0;
                });
              },
              tooltip: 'Clear tiles',
            ),
            _buildIconButton(
              icon: Icons.help_outline,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tap on a floor plane to visualize tiles'),
                  ),
                );
              },
              tooltip: 'Help',
            ),
          ],
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

            // Tile mode instruction overlay
            if (_unityReady && _tileCount == 0)
              Positioned(
                top: 100,
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
                      'Tap on a floor to visualize tiles',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // Tile count display
            if (_unityReady && _tileCount > 0)
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.grid_on, color: Color(0xFF2C2A6D)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tiles needed',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_tileCount tiles',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C2A6D),
                                ),
                              ),
                            ],
                          ),
                          if (_totalArea > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Total area',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_totalArea.toStringAsFixed(2)} m²',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
