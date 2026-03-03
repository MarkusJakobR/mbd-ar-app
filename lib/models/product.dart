class Product {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final String category;
  final String furnitureType;
  final String material;
  final Map<String, dynamic> dimensions; // Changed from Map<String, double>
  final String imageUrl;
  final String modelUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    required this.category,
    required this.furnitureType,
    required this.material,
    required this.dimensions,
    required this.imageUrl,
    required this.modelUrl,
    required this.createdAt,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      furnitureType: data['furnitureType'] ?? '',
      material: data['material'] ?? '',
      dimensions: Map<String, dynamic>.from(data['dimensions'] ?? {}),
      imageUrl: data['imageUrl'] ?? '',
      modelUrl: data['modelUrl'] ?? '',
      createdAt: (data['createdAt'] as dynamic).toDate(),
    );
  }

  // Helper getters for dimensions
  double get height => (dimensions['height'] ?? 0).toDouble();
  double get width => (dimensions['width'] ?? 0).toDouble();
  double get depth => (dimensions['depth'] ?? 0).toDouble();
  String get unit => dimensions['unit'] ?? 'cm';
}
