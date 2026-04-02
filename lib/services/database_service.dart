import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'furniture_cache.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Products cache table
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            name TEXT,
            brand TEXT,
            description TEXT,
            price REAL,
            category TEXT,
            furniture_type TEXT,
            material TEXT,
            height REAL,
            width REAL,
            length REAL,
            unit TEXT,
            image_url TEXT,
            model_url TEXT,
            placement_type TEXT,
            created_at TEXT,
            cached_at TEXT
          )
        ''');

        // Favorites table — just product IDs
        await db.execute('''
          CREATE TABLE favorites (
            product_id TEXT PRIMARY KEY
          )
        ''');
      },
    );
  }

  // ── Products ──────────────────────────────────────────

  Future<void> cacheProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    for (final p in products) {
      batch.insert('products', {
        'id': p.id,
        'name': p.name,
        'brand': p.brand,
        'description': p.description,
        'price': p.price,
        'category': p.category,
        'furniture_type': p.furnitureType,
        'material': p.material,
        'height': p.height,
        'width': p.width,
        'length': p.length,
        'unit': p.unit,
        'image_url': p.imageUrl,
        'model_url': p.modelUrl,
        'placement_type': p.placementType,
        'created_at': p.createdAt.toIso8601String(),
        'cached_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Product>> getCachedProducts() async {
    final db = await database;
    final maps = await db.query('products');
    return maps.map((map) => Product.fromMap(_toProductMap(map))).toList();
  }

  Future<DateTime?> getLastCacheTime() async {
    final db = await database;
    final result = await db.query(
      'products',
      columns: ['cached_at'],
      orderBy: 'cached_at DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return DateTime.tryParse(result.first['cached_at'] as String);
  }

  // SQLite uses snake_case — map back to what Product.fromMap expects
  Map<String, dynamic> _toProductMap(Map<String, dynamic> map) => {
    'id': map['id'],
    'name': map['name'],
    'brand': map['brand'],
    'description': map['description'],
    'price': map['price'],
    'category': map['category'],
    'furniture_type': map['furniture_type'],
    'material': map['material'],
    'height': map['height'],
    'width': map['width'],
    'length': map['length'],
    'unit': map['unit'],
    'image_url': map['image_url'],
    'model_url': map['model_url'],
    'placement_type': map['placement_type'],
    'created_at': map['created_at'],
  };

  // ── Favorites ─────────────────────────────────────────

  Future<void> addFavorite(String productId) async {
    final db = await database;
    await db.insert('favorites', {
      'product_id': productId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFavorite(String productId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<Set<String>> getFavoriteIds() async {
    final db = await database;
    final maps = await db.query('favorites');
    return maps.map((m) => m['product_id'] as String).toSet();
  }

  Future<bool> isFavorite(String productId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return result.isNotEmpty;
  }
}
