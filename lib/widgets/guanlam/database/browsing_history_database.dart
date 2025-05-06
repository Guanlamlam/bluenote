import 'package:bluenote/widgets/guanlam/models/browsing_history_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class BrowsingHistoryDatabase {
  static final BrowsingHistoryDatabase instance = BrowsingHistoryDatabase._init();
  static Database? _database;

  BrowsingHistoryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('browsing_history.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        content TEXT,
        author TEXT,
        authorProfileURL TEXT,
        imagesURL TEXT NOT NULL,
        viewedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertOrUpdateHistory(BrowsingHistoryModel history) async {
    final db = await instance.database;
    await db.insert(
      'history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  Future<List<BrowsingHistoryModel>> getAllHistory() async {
    final db = await instance.database;
    final result = await db.query('history', orderBy: 'viewedAt DESC');
    return result.map((map) => BrowsingHistoryModel.fromMap(map)).toList();
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('history');
  }

  Future<void> maintainHistoryLimit(int maxItems) async {
    final db = await instance.database;
    final result = await db.query('history', orderBy: 'viewedAt DESC');
    if (result.length > maxItems) {
      final excess = result.skip(maxItems);
      for (final row in excess) {
        await db.delete('history', where: 'id = ?', whereArgs: [row['id']]);
      }
    }
  }

  Future<void> deleteAllHistory() async {
    final db = await instance.database;
    await db.delete('history');
  }

}
