import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../services/api_service.dart';

class LaundryProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<CollectionItem> _inLaundryItems = [];
  List<CollectionItem> _readyToStoreItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CollectionItem> get inLaundryItems => _inLaundryItems;
  List<CollectionItem> get readyToStoreItems => _readyToStoreItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLaundryItems() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final inLaundryFuture = _api.getItems(status: 'In Laundry');
      final readyFuture = _api.getItems(status: 'Ready to Store');

      final results = await Future.wait([inLaundryFuture, readyFuture]);
      _inLaundryItems = results[0];
      _readyToStoreItems = results[1];
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startLaundry(String itemId, {String? laundryLocationId, String? notes}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _api.startLaundry(itemId, laundryLocationId: laundryLocationId, notes: notes);
      await fetchLaundryItems();
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

  Future<bool> completeLaundry(String itemId, {String? dryingLocationId, String? notes}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _api.completeLaundry(itemId, dryingLocationId: dryingLocationId, notes: notes);
      await fetchLaundryItems();
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

  Future<bool> storeItem(String itemId, String targetLocationId, {String? positionDetail, String? notes}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _api.storeItem(itemId, targetLocationId, positionDetail: positionDetail, notes: notes);
      await fetchLaundryItems();
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
