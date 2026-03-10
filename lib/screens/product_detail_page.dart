import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import 'ar_view_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              // TODO: Add to favorites
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: Share product
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery
                  _buildImageGallery(),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Brand
                        Text(
                          widget.product.brand,
                          style: const TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Price
                        Text(
                          '₱${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2C2A6D),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Divider(color: Colors.grey[300]),
                        const SizedBox(height: 24),

                        // Description Section
                        _buildSection(
                          'Description',
                          widget.product.description,
                        ),
                        const SizedBox(height: 24),

                        // Dimensions Section
                        _buildSection(
                          'Dimensions',
                          '${widget.product.height.toStringAsFixed(0)}H × '
                              '${widget.product.width.toStringAsFixed(0)}W × '
                              '${widget.product.length.toStringAsFixed(0)}L ${widget.product.unit}',
                        ),
                        const SizedBox(height: 24),

                        // Material Section
                        _buildSection('Material', widget.product.material),
                        const SizedBox(height: 24),

                        // Category Section
                        _buildSection('Category', widget.product.category),
                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom AR Button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    // TODO: Later support multiple images
    // For now, showing single image with placeholder for gallery dots
    return Column(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Image.asset(
              'assets/images/chair_001.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Image indicators (dots)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3, // TODO: Replace with actual image count
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentImageIndex
                    ? const Color(0xFF2C2A6D)
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: const Color(0xFF757575),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ARViewPage(product: widget.product),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2A6D),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.view_in_ar, size: 24),
                const SizedBox(width: 8),
                Text(
                  'View in AR',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
