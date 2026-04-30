import 'package:flutter_test/flutter_test.dart';
import 'package:trak/models/inventory_item.dart';

void main() {
  group('neverExpires', () {
    test('is far enough in the future to never trigger expiry', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(neverExpires, greaterThan(now));
    });

    test('is representable as an int (not double overflow)', () {
      expect(neverExpires, isA<int>());
    });
  });

  group('InventoryItem.fromMap', () {
    test('parses powerup item', () {
      final map = {
        'item_id': 'item-1',
        'name': 'Speed Boost',
        'description': 'Run faster',
        'type': 'powerup',
        'expires_at': 9999999999000,
      };

      final item = InventoryItem.fromMap(map);

      expect(item.itemId, 'item-1');
      expect(item.name, 'Speed Boost');
      expect(item.description, 'Run faster');
      expect(item.type, ItemType.powerup);
      expect(item.expiresAt, 9999999999000);
    });

    test('parses attack item', () {
      final map = {
        'item_id': 'item-2',
        'name': 'Slow Down',
        'description': 'Slows a friend',
        'type': 'attack',
        'expires_at': neverExpires,
      };

      final item = InventoryItem.fromMap(map);

      expect(item.type, ItemType.attack);
    });

    test('throws on unknown item type', () {
      final map = {
        'item_id': 'item-3',
        'name': 'Mystery',
        'description': '?',
        'type': 'unknown_type',
        'expires_at': 0,
      };

      expect(() => InventoryItem.fromMap(map), throwsStateError);
    });
  });

  group('InventoryItem.toMap', () {
    test('serializes fields to snake_case', () {
      final item = InventoryItem(
        itemId: 'item-1',
        name: 'Speed Boost',
        description: 'Run faster',
        type: ItemType.powerup,
        expiresAt: neverExpires,
      );

      final map = item.toMap();

      expect(map['item_id'], 'item-1');
      expect(map['name'], 'Speed Boost');
      expect(map['description'], 'Run faster');
      expect(map['type'], 'powerup');
      expect(map['expires_at'], neverExpires);
    });

    test('fromMap → toMap round-trip is lossless', () {
      final original = {
        'item_id': 'item-9',
        'name': 'Shield',
        'description': 'Block attacks',
        'type': 'powerup',
        'expires_at': 1000000,
      };

      final map = InventoryItem.fromMap(original).toMap();

      expect(map['item_id'], original['item_id']);
      expect(map['name'], original['name']);
      expect(map['type'], original['type']);
      expect(map['expires_at'], original['expires_at']);
    });
  });
}
