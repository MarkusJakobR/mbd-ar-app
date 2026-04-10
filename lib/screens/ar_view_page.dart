import 'package:flutter/material.dart';
import '../models/product.dart';
import 'ar_furniture_mode.dart';
import 'ar_tile_mode.dart';

class ARViewPage extends StatelessWidget {
  final Product product;

  const ARViewPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Route to appropriate mode based on product category
    if (product.isTile) {
      return ARTileMode(product: product);
    } else {
      return ARFurnitureMode(product: product);
    }
  }
}
