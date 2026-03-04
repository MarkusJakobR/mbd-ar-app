import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import '../models/product.dart';

class ARViewPage extends StatelessWidget {
  final Product product;

  const ARViewPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: UnityWidget(
        onUnityCreated: (controller) {
          print('Unity loaded for ${product.name}');
          // Later: send product data to Unity
          // controller.postMessage('ProductManager', 'LoadModel', product.modelUrl);
        },
      ),
    );
  }
}
