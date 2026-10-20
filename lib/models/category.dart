class Category {
  final String id;
  final String name;
  final DateTime? createdAt;
  final int itemCount;

  Category({
    required this.id,
    required this.name,
    this.createdAt,
    this.itemCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      itemCount: json['item_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
