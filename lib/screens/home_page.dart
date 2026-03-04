import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../widgets/product_grid.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Furniture Catalog'), elevation: 0),
      body: StreamBuilder<List<Product>>(
        stream: firestoreService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ProductGrid(products: products);
        },
      ),
    );
  }
}
