import 'package:flutter/material.dart';
import '../models/product.dart';
import 'database_service.dart';

class FavoritesService extends ChangeNotifier {
  final _db = DatabaseService();
  Set<String> _favoriteIds = {};
  bool _isInitialized = false;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    _favoriteIds = await _db.getFavoriteIds();
    _isInitialized = true;
    notifyListeners();
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> toggleFavorite(Product product) async {
    if (_favoriteIds.contains(product.id)) {
      await _db.removeFavorite(product.id);
      _favoriteIds.remove(product.id);
    } else {
      await _db.addFavorite(product.id);
      _favoriteIds.add(product.id);
    }
    notifyListeners();
  }

  Future<List<Product>> getFavoriteProducts(List<Product> allProducts) async {
    return allProducts.where((p) => _favoriteIds.contains(p.id)).toList();
  }
}
