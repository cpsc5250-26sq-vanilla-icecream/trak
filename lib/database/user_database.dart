import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';

class UserDatabase {
  static final UserDatabase instance = UserDatabase._init();
  static Database? _db;

  UserDatabase._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('user.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        userId TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        displayName TEXT NOT NULL,
        avatarUrl TEXT
      )
    ''');
  }

  // READ
  Future<UserProfile?> getUser(String userId) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return UserProfile.fromMap(result.first);
    }
    return null;
  }

  // CREATE
  Future<void> createUser(UserProfile user) async {
    final db = await database;

    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // UPDATE
  Future<void> updateUser(UserProfile user) async {
    final db = await database;

    await db.update(
      'users',
      user.toMap(),
      where: 'userId = ?',
      whereArgs: [user.userId],
    );
  }
}