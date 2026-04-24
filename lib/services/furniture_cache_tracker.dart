import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FurnitureCacheTracker {
  static const _fileName = 'furniture_cache.txt';

  static Future<String> _getFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  static Future<void> markCached(String productId, String productName) async {
    try {
      final path = await _getFilePath();
      final file = File(path);

      // Read existing entries
      final existing = await _readEntries();

      // Only add if not already tracked
      if (existing.containsKey(productId)) return;

      final entry =
          '$productId|$productName|${DateTime.now().toIso8601String()}\n';
      await file.writeAsString(entry, mode: FileMode.append);
      print('Furniture cached: $productName');
    } catch (e) {
      print('Failed to track cache: $e');
    }
  }

  static Future<Map<String, Map<String, String>>> _readEntries() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      if (!await file.exists()) return {};

      final lines = await file.readAsLines();
      final Map<String, Map<String, String>> entries = {};

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|');
        if (parts.length >= 3) {
          entries[parts[0]] = {'name': parts[1], 'cachedAt': parts[2]};
        }
      }
      return entries;
    } catch (e) {
      return {};
    }
  }

  static Future<bool> isCached(String productId) async {
    final entries = await _readEntries();
    return entries.containsKey(productId);
  }

  static Future<String> readForDisplay() async {
    final entries = await _readEntries();
    if (entries.isEmpty) return 'No furniture cached yet.';

    final buffer = StringBuffer();
    buffer.writeln('Cached Furniture (${entries.length} products)');
    buffer.writeln('==============================');

    for (final entry in entries.entries) {
      final date = DateTime.tryParse(entry.value['cachedAt'] ?? '');
      final formatted = date != null
          ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
          : 'Unknown';
      buffer.writeln('• ${entry.value['name']}');
      buffer.writeln('  Cached at: $formatted');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  static Future<void> clear() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      if (await file.exists()) await file.delete();
      print('Furniture cache tracker cleared');
    } catch (e) {
      print('Failed to clear cache tracker: $e');
    }
  }
}
