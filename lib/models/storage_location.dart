class StorageLocation {
  final String id;
  final String name;
  final String? parentLocationId;
  final String? locationType;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int itemCount;
  final List<StorageLocation> children;
  final StorageLocation? parent;

  StorageLocation({
    required this.id,
    required this.name,
    this.parentLocationId,
    this.locationType,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.itemCount = 0,
    this.children = const [],
    this.parent,
  });

  factory StorageLocation.fromJson(Map<String, dynamic> json) {
    List<StorageLocation> childrenList = [];
    if (json['children'] != null && json['children'] is List) {
      childrenList = (json['children'] as List)
          .map((item) => StorageLocation.fromJson(item))
          .toList();
    }

    return StorageLocation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      parentLocationId: json['parent_location_id'],
      locationType: json['location_type'],
      description: json['description'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      itemCount: json['item_count'] ?? 0,
      children: childrenList,
      parent: json['parent'] != null ? StorageLocation.fromJson(json['parent']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_location_id': parentLocationId,
      'location_type': locationType,
      'description': description,
    };
  }
}
