import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/product_detail_page.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[400]!, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 48, 12, 12),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/chair_001.png',
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                        ), // Unfilled heart
                        // icon: const Icon(Icons.favorite), // Filled heart (for favorited state)
                        color: Colors.grey[700],
                        iconSize: 24,
                        onPressed: () {
                          // TODO: Add favorite functionality
                          print('Favorite tapped for ${product.name}');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Brand
                    Text(
                      product.brand,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),

                    // Dimensions
                    Text(
                      '${product.height.toStringAsFixed(0)} x ${product.width.toStringAsFixed(0)} x ${product.length.toStringAsFixed(0)} ${product.unit}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 4),

                    // Price
                    Text(
                      '₱${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2C2A6D),
                      ),
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
