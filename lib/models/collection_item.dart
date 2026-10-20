import 'category.dart';
import 'storage_location.dart';

class CollectionItem {
  final String id;
  final String name;
  final String categoryId;
  final String? imageUrl;
  final String? color;
  final String? brand;
  final String? size;
  final String? currentLocationId;
  final String? positionDetail;
  final String availabilityStatus;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Category? category;
  final StorageLocation? currentLocation;

  CollectionItem({
    required this.id,
    required this.name,
    required this.categoryId,
    this.imageUrl,
    this.color,
    this.brand,
    this.size,
    this.currentLocationId,
    this.positionDetail,
    required this.availabilityStatus,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.currentLocation,
  });

  bool get isAvailable => availabilityStatus == 'Available';
  bool get isInUse => availabilityStatus == 'In Use';
  bool get isInLaundry => availabilityStatus == 'In Laundry';
  bool get isReadyToStore => availabilityStatus == 'Ready to Store';
  bool get isUnavailable => availabilityStatus == 'Unavailable';

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? '',
      imageUrl: json['image_url'],
      color: json['color'],
      brand: json['brand'],
      size: json['size'],
      currentLocationId: json['current_location_id'],
      positionDetail: json['position_detail'],
      availabilityStatus: json['availability_status'] ?? 'Available',
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      currentLocation: json['current_location'] != null ? StorageLocation.fromJson(json['current_location']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'image_url': imageUrl,
      'color': color,
      'brand': brand,
      'size': size,
      'current_location_id': currentLocationId,
      'position_detail': positionDetail,
      'availability_status': availabilityStatus,
      'notes': notes,
    };
  }
}
