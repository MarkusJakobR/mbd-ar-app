import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/product.dart';
import 'database_service.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;
  final _db = DatabaseService();

  // This provides a real-time stream of the products table
  // Stream<List<Product>> getProductsStream() {
  //   return _supabase
  //       .from('temp_products')
  //       .stream(primaryKey: ['id']) // Supabase needs to know the PK for streams
  //       .map((data) => data.map((map) => Product.fromMap(map)).toList());
  // }

  // Use this if you just want a one-time fetch (Future)
  Future<List<Product>> getProductsFuture() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.any(
      (r) => r != ConnectivityResult.none,
    );

    if (isOnline) {
      try {
        final data = await _supabase
            .from('temp_products')
            .select()
            .order('created_at', ascending: false);

        final products = (data as List)
            .map((map) => Product.fromMap(map))
            .toList();

        // Cache fresh data
        await _db.cacheProducts(products);
        return products;
      } catch (e) {
        // Network failed despite being online — fall back to cache
        print('Supabase fetch failed, using cache: $e');
        return _db.getCachedProducts();
      }
    } else {
      // Offline — use cache
      print('Offline — loading from cache');
      return _db.getCachedProducts();
    }
  }
}
