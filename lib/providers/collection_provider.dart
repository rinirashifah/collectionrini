import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/collection_item.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';

class CollectionProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<CollectionItem> _items = [];
  List<Category> _categories = [];
  DashboardData? _dashboardData;

  bool _isLoading = false;
  String? _errorMessage;

  // Active Filters
  String? _selectedCategoryId;
  String? _selectedStatus;
  String _searchQuery = '';
  String? _selectedLocationId;

  List<CollectionItem> get items => _items;
  List<Category> get categories => _categories;
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  String? get selectedLocationId => _selectedLocationId;

  Future<void> loadDashboard() async {
    try {
      _isLoading = true;
      notifyListeners();

      _dashboardData = await _api.getDashboard();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _api.getCategories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchItems() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _items = await _api.getItems(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _selectedCategoryId,
        status: _selectedStatus,
        locationId: _selectedLocationId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchItems();
  }

  void setCategoryFilter(String? categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null; // Toggle off
    } else {
      _selectedCategoryId = categoryId;
    }
    fetchItems();
  }

  void setStatusFilter(String? status) {
    if (_selectedStatus == status) {
      _selectedStatus = null; // Toggle off
    } else {
      _selectedStatus = status;
    }
    fetchItems();
  }

  void setLocationFilter(String? locationId) {
    _selectedLocationId = locationId;
    fetchItems();
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _selectedStatus = null;
    _searchQuery = '';
    _selectedLocationId = null;
    fetchItems();
  }

  Future<bool> addItem(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _api.createItem(data);
      await fetchItems();
      await loadDashboard();
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

  Future<bool> updateItem(String id, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _api.updateItem(id, data);
      await fetchItems();
      await loadDashboard();
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

  Future<bool> deleteItem(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _api.deleteItem(id);
      _items.removeWhere((item) => item.id == id);
      await loadDashboard();
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

  Future<bool> addCategory(String name) async {
    try {
      final newCat = await _api.createCategory(name);
      _categories.add(newCat);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
