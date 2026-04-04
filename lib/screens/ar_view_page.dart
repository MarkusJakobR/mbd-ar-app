import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import '../models/product.dart';

class ARViewPage extends StatefulWidget {
  final Product product;
  const ARViewPage({super.key, required this.product});

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> with WidgetsBindingObserver {
  UnityWidgetController? _unityController;
  bool _unityReady = false;

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

  void onUnityMessage(message) {
    print('Message from Unity: $message');
    if (message.toString() == 'OnUnityReady' && !_unityReady) {
      if (mounted) setState(() => _unityReady = true);
      _sendProductToUnity();
    }
  }

  void _sendProductToUnity() {
    if (_unityController == null) return;
    final message = jsonEncode(widget.product.toUnityMessage());
    print('Sending to Unity: $message');
    _unityController!.postMessage('ARManager', 'OnProductSelected', message);
    print('Product sent to Unity: ${widget.product.name}');
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
          ],
        ),
      ),
    );
  }
}
