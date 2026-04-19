import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/product.dart';
import 'database_service.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;
  final _db = DatabaseService();

  // Use this if you just want a one-time fetch (Future)
  Future<List<Product>> getProductsFuture() async {
    // Check cache first
    final cached = await _db.getCachedProducts();
    if (cached.isNotEmpty) {
      // Return cache immediately, refresh in background
      _refreshInBackground();
      return cached;
    }

    // No cache — fetch from network
    try {
      return await _fetchFromNetwork();
    } catch (e) {
      print('Fetch failed, cache empty: $e');
      return [];
    }
  }

  Future<void> _refreshInBackground() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.any(
      (r) => r != ConnectivityResult.none,
    );
    if (!isOnline) return;

    try {
      await _fetchFromNetwork();
      print('Background refresh complete');
    } catch (e) {
      print('Background refresh failed: $e');
    }
  }

  Future<List<Product>> _fetchFromNetwork() async {
    final data = await _supabase
        .from('temp_products')
        .select()
        .order('created_at', ascending: false);
    final products = (data as List).map((map) => Product.fromMap(map)).toList();
    await _db.cacheProducts(products);
    return products;
  }
}
