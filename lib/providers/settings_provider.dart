import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum ConnectionStatus { initial, testing, connected, failed }

class SettingsProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  String _baseUrl = StorageService.defaultBaseUrl;
  String _apiKey = StorageService.defaultApiKey;
  ConnectionStatus _connectionStatus = ConnectionStatus.initial;
  String? _statusMessage;
  bool _isSeeding = false;

  String get baseUrl => _baseUrl;
  String get apiKey => _apiKey;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get statusMessage => _statusMessage;
  bool get isSeeding => _isSeeding;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _baseUrl = await StorageService.getBaseUrl();
    _apiKey = await StorageService.getApiKey();
    notifyListeners();
    testConnection();
  }

  Future<void> saveSettings(String url, String key) async {
    _baseUrl = url.trim();
    _apiKey = key.trim();
    await StorageService.setBaseUrl(_baseUrl);
    await StorageService.setApiKey(_apiKey);
    notifyListeners();
    await testConnection();
  }

  Future<void> testConnection() async {
    _connectionStatus = ConnectionStatus.testing;
    _statusMessage = 'Menghubungkan ke server...';
    notifyListeners();

    final isHealthy = await _api.checkHealth(_baseUrl, _apiKey);
    if (isHealthy) {
      _connectionStatus = ConnectionStatus.connected;
      _statusMessage = 'Terhubung online ✨';
    } else {
      _connectionStatus = ConnectionStatus.failed;
      _statusMessage = 'Gagal terhubung ke backend';
    }
    notifyListeners();
  }

  Future<bool> seedSampleData() async {
    try {
      _isSeeding = true;
      notifyListeners();

      await _api.seedSampleData();
      _isSeeding = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isSeeding = false;
      notifyListeners();
      return false;
    }
  }
}
