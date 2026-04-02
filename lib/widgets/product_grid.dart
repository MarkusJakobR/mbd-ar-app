import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_card.dart';
import '../services/favorites_service.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final FavoritesService favoritesService;

  const ProductGrid({
    super.key,
    required this.products,
    required this.favoritesService,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns
        childAspectRatio: 0.7, // Adjust for card height
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          favoritesService: favoritesService,
        );
      },
    );
  }
}
