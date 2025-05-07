import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:bluenote/model/draft_model.dart';

class DraftDatabase {
  static final DraftDatabase instance = DraftDatabase._init();
  static Database? _database;

  DraftDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'drafts.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE drafts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT,
            item TEXT,
            contact TEXT,
            contactNumber TEXT,
            location TEXT,
            type TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
    return _database!;
  }

  Future<void> insertDraft(DraftPost draft) async {
    final db = await instance.database;
    await db.insert('drafts', draft.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
