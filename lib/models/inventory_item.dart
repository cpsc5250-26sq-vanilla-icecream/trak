enum ItemType { powerup, attack }

final neverExpires = DateTime(9999).millisecondsSinceEpoch;

class InventoryItem {
  final String itemId;
  final String name;
  final String description;
  final ItemType type;
  final int expiresAt;

  const InventoryItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.type,
    required this.expiresAt,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      itemId: map['item_id'],
      name: map['name'],
      description: map['description'],
      type: ItemType.values.firstWhere((e) => e.name == map['type']),
      expiresAt: map['expires_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'name': name,
      'description': description,
      'type': type.name,
      'expires_at': expiresAt,
    };
  }
}
