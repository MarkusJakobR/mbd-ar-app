import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../widgets/product_grid.dart';
import '../widgets/product_search_delegate.dart';
import '../widgets/filter_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabaseService = SupabaseService();
  List<Product> products = [];
  String selectedFilter = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Furniture Catalog'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(allProducts: products),
              );
            },
          ),
        ],
      ),
      // endDrawer: FilterDrawer(filterType: selectedFilter),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          FilterBar(
            onFilterTap: (filterName) {
              setState(() => selectedFilter = filterName);
              Scaffold.of(context).openEndDrawer();
            },
          ),
          const Divider(height: 20),

          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: supabaseService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                products = snapshot.data ?? [];

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
          ),
        ],
      ),
    );
  }
}
