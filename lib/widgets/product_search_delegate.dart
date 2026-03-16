import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_card.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> allProducts;

  ProductSearchDelegate({required this.allProducts});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = allProducts.where((p) => p.matchesSearch(query)).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No products found.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) => ProductCard(product: results[index]),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = allProducts
        .where((p) => p.matchesSearch(query))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final product = suggestions[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text("${product.brand} • ${product.material}"),
          onTap: () {
            query = product.name;
            showResults(context);
          },
        );
      },
    );
  }
}
