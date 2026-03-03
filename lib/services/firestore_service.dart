import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all products as a stream
  Stream<List<Product>> getProducts() {
    return _db
        .collection('products')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _db
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get products by furniture type
  Stream<List<Product>> getProductsByFurnitureType(String furnitureType) {
    return _db
        .collection('products')
        .where('furnitureType', isEqualTo: furnitureType)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get products by material
  Stream<List<Product>> getProductsByMaterial(String material) {
    return _db
        .collection('products')
        .where('material', isEqualTo: material)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get products by brand
  Stream<List<Product>> getProductsByBrand(String brand) {
    return _db
        .collection('products')
        .where('brand', isEqualTo: brand)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get single product by ID
  Future<Product?> getProduct(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    if (doc.exists) {
      return Product.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }
}
