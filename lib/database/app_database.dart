import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _db;

  AppDatabase._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('user.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE leaderboard_cache (
      user_id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      avatar_url TEXT,
      points INTEGER NOT NULL,
      rank INTEGER NOT NULL,
      cached_at INTEGER NOT NULL
      )
      ''');
    await db.execute('''
      CREATE TABLE step_history_cache (
      user_id TEXT NOT NULL,
      date TEXT NOT NULL,
      step_count INTEGER NOT NULL,
      cached_at INTEGER NOT NULL,
      PRIMARY KEY (user_id, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_cache (
      user_id TEXT NOT NULL,
      item_id TEXT NOT NULL,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      type TEXT NOT NULL,
      expires_at INTEGER NOT NULL,
      PRIMARY KEY (user_id, item_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_meta (
      data_type TEXT PRIMARY KEY,
      last_synced_at INTEGER NOT NULL
      )
    ''');
  }

  // LEADERBOARD
  // Get new leaderboard
  Future<void> replaceLeaderboard(List<Map<String, dynamic>> data) async {
    final db = await database;
    await db.delete('leaderboard_cache');
    for (final row in data) {
      await db.insert('leaderboard_cache', row);
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final db = await database;
    final row = await db.query('leaderboard_cache', orderBy: 'rank ASC');
    return row.map((e) => LeaderboardEntry.fromMap(e)).toList();
  }

  // STEPS QUERIES
  // Update Steps Count
  Future<void> upsertSteps({
    required String userId,
    required String date,
    required int stepCount,
  }) async {
    final db = await database;
    await db.insert("step_history_cache", {
      'user_id': userId,
      'date': date,
      'step_count': stepCount,
      'cached_at': DateTime.now(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get Step Count
  Future<int?> getCurrentSteps({
    required String userId,
    required String date,
  }) async {
    final db = await database;
    final result = await db.query(
      'step_history_cache',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    if (result.isNotEmpty) {
      return result.first['step_count'] as int;
    }
    return null;
  }

  // ITEM INVENTORY
  // Update Inventory
  Future<void> replaceInventory(
    String userId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await database;
    await db.delete(
      'inventory_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    for (final item in items) {
      item['user_id'] = userId;
      await db.insert('inventory_cache', item);
    }
  }

  // Get inventory
  Future<List<InventoryItem>> getInventory(String userId) async {
    final db = await database;

    final row = await db.query(
      'inventory_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return row.map((e) => InventoryItem.fromMap(e)).toList();
  }

  // SYNC META
  // Update the time in Sync Table
  Future<void> updateSyncTime(String type) async {
    final db = await database;

    await db.insert('sync_meta', {
      'data_type': type,
      'last_synced_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get the last synced time
  Future<int?> getLastSyncTime(String type) async {
    final db = await database;

    final result = await db.query(
      'sync_meta',
      where: 'data_type = ?',
      whereArgs: [type],
    );

    if (result.isNotEmpty) {
      return result.first['last_synced_at'] as int;
    }
    return null;
  }
}
