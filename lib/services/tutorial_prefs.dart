import 'package:shared_preferences/shared_preferences.dart';

class TutorialPrefs {
  static const _furnitureKey = 'hasSeenFurnitureTutorial';
  static const _tileKey = 'hasSeenTileTutorial';

  static Future<bool> hasSeenFurnitureTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_furnitureKey) ?? false;
  }

  static Future<bool> hasSeenTileTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tileKey) ?? false;
  }

  static Future<void> markFurnitureTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_furnitureKey, true);
  }

  static Future<void> markTileTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tileKey, true);
  }

  // For help button — resets so tutorial shows again
  static Future<void> resetFurnitureTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_furnitureKey, false);
  }

  static Future<void> resetTileTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tileKey, false);
  }
}
