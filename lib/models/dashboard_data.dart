import 'collection_item.dart';

class StatusSummary {
  final int total;
  final int available;
  final int inUse;
  final int inLaundry;
  final int readyToStore;
  final int unavailable;

  StatusSummary({
    this.total = 0,
    this.available = 0,
    this.inUse = 0,
    this.inLaundry = 0,
    this.readyToStore = 0,
    this.unavailable = 0,
  });

  factory StatusSummary.fromJson(Map<String, dynamic> json) {
    return StatusSummary(
      total: json['total'] ?? 0,
      available: json['available'] ?? 0,
      inUse: json['in_use'] ?? 0,
      inLaundry: json['in_laundry'] ?? 0,
      readyToStore: json['ready_to_store'] ?? 0,
      unavailable: json['unavailable'] ?? 0,
    );
  }
}

class DashboardData {
  final StatusSummary summary;
  final List<CollectionItem> inLaundryItems;
  final List<CollectionItem> readyToStoreItems;
  final List<CollectionItem> recentItems;
  final int totalCategories;
  final int totalLocations;

  DashboardData({
    required this.summary,
    this.inLaundryItems = const [],
    this.readyToStoreItems = const [],
    this.recentItems = const [],
    this.totalCategories = 0,
    this.totalLocations = 0,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    List<CollectionItem> inLaundry = [];
    if (json['in_laundry_items'] != null && json['in_laundry_items'] is List) {
      inLaundry = (json['in_laundry_items'] as List)
          .map((item) => CollectionItem.fromJson(item))
          .toList();
    }

    List<CollectionItem> readyToStore = [];
    if (json['ready_to_store_items'] != null && json['ready_to_store_items'] is List) {
      readyToStore = (json['ready_to_store_items'] as List)
          .map((item) => CollectionItem.fromJson(item))
          .toList();
    }

    List<CollectionItem> recent = [];
    if (json['recent_items'] != null && json['recent_items'] is List) {
      recent = (json['recent_items'] as List)
          .map((item) => CollectionItem.fromJson(item))
          .toList();
    }

    return DashboardData(
      summary: StatusSummary.fromJson(json['summary'] ?? {}),
      inLaundryItems: inLaundry,
      readyToStoreItems: readyToStore,
      recentItems: recent,
      totalCategories: json['total_categories'] ?? 0,
      totalLocations: json['total_locations'] ?? 0,
    );
  }
}
