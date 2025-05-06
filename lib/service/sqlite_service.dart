import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteService {
  // singleton
  SQLiteService._();
  static final SQLiteService instance = SQLiteService._();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('drafts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  FutureOr<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drafts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        item TEXT,
        contact TEXT,
        contactNumber TEXT,
        location TEXT,
        type TEXT,
        imagePaths TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<void> insertDraft(Map<String, dynamic> draft) async {
    final db = await instance.database;
    // we serialize list of paths into a JSON‐style string
    final mod = Map<String, dynamic>.from(draft);
    if (mod['imagePaths'] is List) {
      mod['imagePaths'] = (mod['imagePaths'] as List).join('||');
    }
    await db.insert(
      'drafts',
      mod,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllDrafts() async {
    final db = await database;
    return db.query('drafts', orderBy: 'timestamp DESC');
  }

  Future<Map<String, dynamic>?> getDraftById(int id) async {
    final db = await database;
    final rows = await db.query('drafts', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> deleteDraft(int id) async {
    final db = await database;
    await db.delete('drafts', where: 'id = ?', whereArgs: [id]);
  }
}
