import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/ar_view_page.dart';

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
              builder: (context) => ARViewPage(product: product),
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
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
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
                  // child: product.imageUrl.isNotEmpty
                  //     ? Image.network(
                  //         product.imageUrl,
                  //         width: double.infinity,
                  //         fit: BoxFit.contain,
                  //         loadingBuilder: (context, child, loadingProgress) {
                  //           if (loadingProgress == null) return child;
                  //           return Center(
                  //             child: CircularProgressIndicator(
                  //               value:
                  //                   loadingProgress.expectedTotalBytes != null
                  //                   ? loadingProgress.cumulativeBytesLoaded /
                  //                         loadingProgress.expectedTotalBytes!
                  //                   : null,
                  //             ),
                  //           );
                  //         },
                  //         errorBuilder: (context, error, stackTrace) {
                  //           return Center(
                  //             child: Icon(
                  //               Icons.broken_image,
                  //               size: 40,
                  //               color: Colors.grey[400],
                  //             ),
                  //           );
                  //         },
                  //       )
                  //     : Center(
                  //         child: Icon(
                  //           Icons.chair,
                  //           size: 60,
                  //           color: Colors.grey[400],
                  //         ),
                  //       ),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),

                    // Dimensions
                    Text(
                      '${product.height.toStringAsFixed(0)} x ${product.width.toStringAsFixed(0)} x ${product.length.toStringAsFixed(0)} ${product.unit}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 4),

                    // Price
                    Text(
                      '₱${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
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
