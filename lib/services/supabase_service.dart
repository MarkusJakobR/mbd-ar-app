import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // This provides a real-time stream of the products table
  Stream<List<Product>> getProductsStream() {
    return _supabase
        .from('temp_products')
        .stream(primaryKey: ['id']) // Supabase needs to know the PK for streams
        .map((data) => data.map((map) => Product.fromMap(map)).toList());
  }

  // Use this if you just want a one-time fetch (Future)
  Future<List<Product>> getProductsFuture() async {
    final data = await _supabase.from('temp_products').select();
    return (data as List).map((map) => Product.fromMap(map)).toList();
  }
}
