class Product {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final String category;
  final String furnitureType;
  final String material;
  final int height;
  final int width;
  final int length;
  final String unit;
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
    required this.height,
    required this.width,
    required this.length,
    required this.unit,
    required this.imageUrl,
    required this.modelUrl,
    required this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      furnitureType: map['furniture_type'] ?? '',
      material: map['material'] ?? '',
      height: map['height'] ?? 0,
      width: map['width'] ?? 0,
      length: map['length'] ?? 0,
      unit: map['unit'] ?? 'cm',
      imageUrl: map['image_url'] ?? '',
      modelUrl: map['model_url'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  // Derives Unity placement type from your existing category/furnitureType fields
  String get placementType {
    switch (category.toLowerCase()) {
      case 'door':
      case 'wall panel':
        return 'VerticalOnly';
      case 'cabinet':
      case 'chair':
      case 'table':
      case 'desk':
      case 'tile':
        return 'HorizontalOnly';
      default:
        return 'Any';
    }
  }

  // What gets sent to Unity — modelUrl holds the addressable key
  Map<String, dynamic> toUnityMessage() => {
    'productId': id,
    'name': name,
    'addressableKey': modelUrl,
    'placementType': placementType,
    'category': category,
    'furnitureType': furnitureType,
  };

  // Helper getters for dimensions
  String get dimensionsString => "$width x $height x $length $unit";

  bool matchesSearch(String query) {
    final lowercaseQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowercaseQuery) ||
        material.toLowerCase().contains(lowercaseQuery) ||
        category.toLowerCase().contains(lowercaseQuery) ||
        brand.toLowerCase().contains(lowercaseQuery);
  }
}
