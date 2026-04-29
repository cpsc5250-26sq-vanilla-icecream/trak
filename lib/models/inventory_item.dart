enum ItemType { powerup, attack }

class InventoryItem {
  final String itemId;
  final String name;
  final String description;
  final ItemType type;

  const InventoryItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.type,
  });
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      itemId: map['item_id'],
      name: map['name'],
      description: map['description'],
      type: ItemType.values.firstWhere((e) => e.name == map['type']),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'item_id': itemId,
      'name': name,
      'description': description,
      'type': type.name,
      'expires_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
