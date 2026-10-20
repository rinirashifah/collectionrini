import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../models/storage_location.dart';
import '../services/api_service.dart';

class LocationProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<StorageLocation> _locations = [];
  List<StorageLocation> _locationTree = [];

  StorageLocation? _currentLocation;
  List<StorageLocation> _currentBreadcrumbs = [];
  List<StorageLocation> _currentChildren = [];
  List<CollectionItem> _currentItems = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<StorageLocation> get locations => _locations;
  List<StorageLocation> get locationTree => _locationTree;
  StorageLocation? get currentLocation => _currentLocation;
  List<StorageLocation> get currentBreadcrumbs => _currentBreadcrumbs;
  List<StorageLocation> get currentChildren => _currentChildren;
  List<CollectionItem> get currentItems => _currentItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLocations() async {
    try {
      _isLoading = true;
      notifyListeners();

      _locations = await _api.getLocations();
      _locationTree = await _api.getLocationTree();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectLocation(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final detail = await _api.getLocationDetail(id);
      _currentLocation = detail['location'];
      _currentBreadcrumbs = detail['breadcrumbs'] ?? [];
      _currentChildren = detail['children'] ?? [];

      _currentItems = await _api.getLocationItems(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedLocation() {
    _currentLocation = null;
    _currentBreadcrumbs = [];
    _currentChildren = [];
    _currentItems = [];
    notifyListeners();
  }

  Future<bool> createLocation(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _api.createLocation(data);
      await fetchLocations();

      if (_currentLocation != null) {
        await selectLocation(_currentLocation!.id);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLocation(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _api.deleteLocation(id);
      await fetchLocations();
      clearSelectedLocation();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
