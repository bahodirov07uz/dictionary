import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';
import '../models/api_word.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dictionary.db');
    return await openDatabase(path, version: 2, onCreate: _createDb, onUpgrade: _onUpgrade);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uzbek TEXT NOT NULL,
        english TEXT NOT NULL,
        is_learned INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        translations TEXT NOT NULL,
        viewed_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word_id INTEGER NOT NULL,
          word TEXT NOT NULL,
          translations TEXT NOT NULL,
          viewed_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ---- Custom words ----
  Future<List<Word>> getAllWords() async {
    final db = await database;
    final maps = await db.query('words', orderBy: 'created_at DESC');
    return maps.map((m) => Word.fromMap(m)).toList();
  }

  Future<Word> insertWord(Word word) async {
    final db = await database;
    final id = await db.insert('words', word.toMap());
    return word.copyWith(id: id);
  }

  Future<void> updateWord(Word word) async {
    final db = await database;
    await db.update('words', word.toMap(), where: 'id = ?', whereArgs: [word.id]);
  }

  Future<void> deleteWord(int id) async {
    final db = await database;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleLearned(Word word) async {
    await updateWord(word.copyWith(isLearned: !word.isLearned));
  }

  // ---- History ----
  Future<void> addToHistory(HistoryItem item) async {
    final db = await database;
    // Remove duplicate if exists
    await db.delete('history', where: 'word_id = ?', whereArgs: [item.wordId]);
    await db.insert('history', item.toMap());
  }

  Future<List<HistoryItem>> getHistory() async {
    final db = await database;
    final maps = await db.query('history', orderBy: 'viewed_at DESC', limit: 100);
    return maps.map((m) => HistoryItem.fromMap(m)).toList();
  }

  Future<void> deleteHistoryItem(int wordId) async {
    final db = await database;
    await db.delete('history', where: 'word_id = ?', whereArgs: [wordId]);
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }
}
