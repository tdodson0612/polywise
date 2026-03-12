// lib/models/grocery_item.dart

class GroceryItem {
  final int? id;
  final String userId;
  final String item;
  final int orderIndex;
  final DateTime createdAt;

  GroceryItem({
    this.id,
    required this.userId,
    required this.item,
    required this.orderIndex,
    required this.createdAt,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'],
      userId: json['user_id'] as String? ?? '',
      // ✅ Support both 'item_name' (new) and 'item' (legacy) column names
      item: (json['item_name'] ?? json['item'] ?? '') as String,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'item_name': item, // ✅ Write to new column name
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns true if this item has the minimum required fields to be usable
  bool isValid() {
    return userId.isNotEmpty && item.trim().isNotEmpty;
  }

  @override
  String toString() {
    return 'GroceryItem(id: $id, item: $item, orderIndex: $orderIndex)';
  }
}