import 'storage_location.dart';

class LocationHistory {
  final String id;
  final String itemId;
  final String? previousLocationId;
  final String? newLocationId;
  final DateTime movedAt;
  final String? notes;
  final StorageLocation? previousLocation;
  final StorageLocation? newLocation;

  LocationHistory({
    required this.id,
    required this.itemId,
    this.previousLocationId,
    this.newLocationId,
    required this.movedAt,
    this.notes,
    this.previousLocation,
    this.newLocation,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) {
    return LocationHistory(
      id: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      previousLocationId: json['previous_location_id'],
      newLocationId: json['new_location_id'],
      movedAt: json['moved_at'] != null
          ? DateTime.parse(json['moved_at'])
          : DateTime.now(),
      notes: json['notes'],
      previousLocation: json['previous_location'] != null
          ? StorageLocation.fromJson(json['previous_location'])
          : null,
      newLocation: json['new_location'] != null
          ? StorageLocation.fromJson(json['new_location'])
          : null,
    );
  }
}
