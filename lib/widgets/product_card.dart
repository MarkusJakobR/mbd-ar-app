import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/product_detail_page.dart';
import '../services/favorites_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final FavoritesService favoritesService;

  const ProductCard({
    super.key,
    required this.product,
    required this.favoritesService,
  });

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
                        child: Image.network(
                          product
                              .imageUrl, // This uses the URL from your database
                          width: double.infinity,
                          height:
                              200, // Explicit height helps prevent layout jumps
                          fit: BoxFit.contain,
                          // Optional: Shows a progress indicator while downloading
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                          // Optional: Shows an icon if the URL is broken or 404
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ListenableBuilder(
                        listenable: favoritesService,
                        builder: (context, _) {
                          final isFav = favoritesService.isFavorite(product.id);
                          return GestureDetector(
                            onTap: () =>
                                favoritesService.toggleFavorite(product),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey,
                                size: 18,
                              ),
                            ),
                          );
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
