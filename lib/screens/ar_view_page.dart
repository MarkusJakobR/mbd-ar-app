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

class _ARViewPageState extends State<ARViewPage> {
  UnityWidgetController? _unityController;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _stopAR();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.product.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _stopAR();
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
        body: UnityWidget(onUnityCreated: onUnityCreated),
      ),
    );
  }

  void onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
    print('Unity loaded for ${widget.product.name}');
    _startAR();
  }

  Future<void> _startAR() async {
    if (_unityController == null) return;

    _unityController!.postMessage('AR Session', 'StartAR', '');
    print('AR session started');

    // Small delay to let Unity fully initialize before sending product
    await Future.delayed(const Duration(milliseconds: 500));
    _sendProductToUnity();
  }

  void _sendProductToUnity() {
    if (_unityController == null) return;

    final message = jsonEncode(widget.product.toUnityMessage());
    _unityController!.postMessage(
      'ARManager', // GameObject name in Unity
      'OnProductSelected', // Method in ARManager.cs
      message,
    );
    print('Product sent to Unity: ${widget.product.name}');
  }

  Future<void> _stopAR() async {
    if (_unityController == null) return;

    _unityController!.postMessage('AR Session', 'StopAR', '');
    print('AR session stopped');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _stopAR();
    _unityController?.dispose();
    super.dispose();
  }
}
