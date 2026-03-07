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
    // TODO: send product to unity and display appropriate product

    _startAR();
  }

  Future<void> _startAR() async {
    if (_unityController != null) {
      _unityController!.postMessage(
        'AR Session', // GameObject name
        'StartAR', // Method name
        '', // Message (empty)
      );
      print('AR session started');
    }
  }

  Future<void> _stopAR() async {
    if (_unityController != null) {
      _unityController!.postMessage(
        'AR Session', // GameObject name
        'StopAR', // Method name
        '', // Message (empty)
      );
      print('AR session stopped');

      // Wait a bit for Unity to process the stop command
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _stopAR();
    _unityController?.dispose();
    super.dispose();
  }
}
