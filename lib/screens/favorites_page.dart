import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/favorites_service.dart';
import '../widgets/product_grid.dart';

class FavoritesPage extends StatefulWidget {
  final List<Product> allProducts;
  final FavoritesService favoritesService;

  const FavoritesPage({
    super.key,
    required this.allProducts,
    required this.favoritesService,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Product> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    widget.favoritesService.addListener(_loadFavorites);
  }

  @override
  void dispose() {
    widget.favoritesService.removeListener(_loadFavorites);
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await widget.favoritesService.getFavoriteProducts(
      widget.allProducts,
    );
    if (mounted) setState(() => _favorites = favorites);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Favorites'),
        automaticallyImplyLeading: false,
      ),
      body: _favorites.isEmpty ? _buildEmpty() : _buildGrid(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart on any product to save it',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return ProductGrid(
      products: _favorites,
      favoritesService: widget.favoritesService,
    );
  }
}
