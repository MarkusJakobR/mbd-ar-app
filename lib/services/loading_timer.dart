import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LoadingTimer {
  static DateTime? _startTime;
  static DateTime? _unityReadyTime;
  static DateTime? _assetsReadyTime;

  static void start() {
    _startTime = DateTime.now();
    _unityReadyTime = null;
    _assetsReadyTime = null;
  }

  static void markUnityReady() {
    _unityReadyTime = DateTime.now();
  }

  static void markAssetsReady() {
    _assetsReadyTime = DateTime.now();
  }

  static Future<void> save(String mode, String productName) async {
    if (_startTime == null) return;

    final now = DateTime.now();
    final totalMs = now.difference(_startTime!).inMilliseconds;
    final unityMs = _unityReadyTime != null
        ? _unityReadyTime!.difference(_startTime!).inMilliseconds
        : -1;
    final assetsMs = _assetsReadyTime != null
        ? _assetsReadyTime!.difference(_startTime!).inMilliseconds
        : -1;

    final entry = [
      '==============================',
      'Mode: $mode',
      'Product: $productName',
      'Timestamp: ${_startTime!.toIso8601String()}',
      'Unity Ready: ${unityMs >= 0 ? '${unityMs}ms' : 'not recorded'}',
      'Assets Ready: ${assetsMs >= 0 ? '${assetsMs}ms' : 'not recorded'}',
      'Total Load Time: ${totalMs}ms',
      '==============================',
      '',
    ].join('\n');

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/loading_times.txt');
      await file.writeAsString(entry, mode: FileMode.append);
      print('Loading time saved: ${totalMs}ms');
      print('File location: ${file.path}');
    } catch (e) {
      print('Failed to save loading time: $e');
    }
  }

  static Future<String> read() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/loading_times.txt');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'No loading times recorded yet.';
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  static Future<void> clear() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/loading_times.txt');
      if (await file.exists()) await file.delete();
      print('Loading times cleared');
    } catch (e) {
      print('Failed to clear loading times: $e');
    }
  }
}
