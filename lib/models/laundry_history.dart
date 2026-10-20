class LaundryHistory {
  final String id;
  final String itemId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? notes;
  final DateTime? createdAt;

  LaundryHistory({
    required this.id,
    required this.itemId,
    required this.startedAt,
    this.completedAt,
    this.notes,
    this.createdAt,
  });

  bool get isCompleted => completedAt != null;

  factory LaundryHistory.fromJson(Map<String, dynamic> json) {
    return LaundryHistory(
      id: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
