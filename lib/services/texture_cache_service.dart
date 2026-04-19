import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TextureCacheService {
  static Future<String> _getCachePath(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final hash = md5.convert(utf8.encode(url)).toString();
    return '${dir.path}/tile_textures/$hash.png';
  }

  static Future<bool> isCached(String url) async {
    final path = await _getCachePath(url);
    return File(path).exists();
  }

  static Future<String?> getCachedPath(String url) async {
    final path = await _getCachePath(url);
    final file = File(path);
    if (await file.exists()) return path;
    return null;
  }

  static Future<String?> downloadAndCache(String url) async {
    try {
      final path = await _getCachePath(url);
      final file = File(path);

      // Create directory if it doesn't exist
      await file.parent.create(recursive: true);

      // Download
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('Texture cached to: $path');
        return path;
      }
      return null;
    } catch (e) {
      print('Texture cache failed: $e');
      return null;
    }
  }

  static Future<String?> getOrDownload(String url) async {
    // Check cache first
    final cached = await getCachedPath(url);
    if (cached != null) {
      print('Texture loaded from cache: $cached');
      return cached;
    }

    // Not cached — download and save
    return await downloadAndCache(url);
  }
}
