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
}
