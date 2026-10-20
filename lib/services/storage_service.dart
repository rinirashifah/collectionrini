import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyBaseUrl = 'backend_base_url';
  static const String _keyApiKey = 'backend_api_key';

  // Default URL: localhost:8080 (or Render production URL when deployed)
  static const String defaultBaseUrl = 'http://10.0.2.2:8080';
  static const String defaultApiKey = 'rini-secret-2024';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url.trim());
  }

  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) != null
        ? (prefs.getString(_keyApiKey) ?? defaultApiKey)
        : defaultApiKey;
  }

  static Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key.trim());
  }
}
