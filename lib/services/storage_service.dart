import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _workshopDataKey = 'workshop_data';

  // Token management
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Workshop data management
  static Future<void> saveWorkshopData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workshopDataKey, data.toString());
  }

  static Future<Map<String, dynamic>?> getWorkshopData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_workshopDataKey);
    if (dataString != null) {
      // Simple parsing - in production, use proper JSON serialization
      return {};
    }
    return null;
  }

  static Future<void> clearWorkshopData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workshopDataKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}









