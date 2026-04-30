import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:trak/models/inventory_item.dart';
import 'package:trak/models/leaderboard_entry.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _db;

  static const syncKeySteps = 'steps';
  static const syncKeyLeaderboard = 'leaderboard';

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
      date TEXT PRIMARY KEY,
      step_count INTEGER NOT NULL,
      cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_cache (
      item_id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      type TEXT NOT NULL,
      expires_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_meta (
      data_type TEXT PRIMARY KEY,
      last_synced_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> replaceLeaderboard(List<LeaderboardEntry> entries) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('leaderboard_cache');
      for (final entry in entries) {
        await txn.insert('leaderboard_cache', entry.toMap());
      }
    });
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final db = await database;
    final row = await db.query('leaderboard_cache', orderBy: 'rank ASC');
    return row.map((e) => LeaderboardEntry.fromMap(e)).toList();
  }

  Future<void> upsertSteps({
    required String date,
    required int stepCount,
  }) async {
    final db = await database;
    await db.insert('step_history_cache', {
      'date': date,
      'step_count': stepCount,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int?> getCurrentSteps({required String date}) async {
    final db = await database;
    final result = await db.query(
      'step_history_cache',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (result.isNotEmpty) {
      return result.first['step_count'] as int;
    }
    return null;
  }

  Future<void> upsertInventory(List<InventoryItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final item in items) {
        await txn.insert(
          'inventory_cache',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> removeInventoryItem(String itemId) async {
    final db = await database;
    await db.delete(
      'inventory_cache',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<InventoryItem>> getInventory() async {
    final db = await database;
    final rows = await db.query('inventory_cache');
    return rows.map((e) => InventoryItem.fromMap(e)).toList();
  }

  Future<void> updateSyncTime(String type) async {
    final db = await database;

    await db.insert('sync_meta', {
      'data_type': type,
      'last_synced_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

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
