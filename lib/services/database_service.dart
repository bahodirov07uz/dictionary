import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';

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
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
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
  }

  // Barcha so'zlarni olish
  Future<List<Word>> getAllWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Word.fromMap(maps[i]));
  }

  // Yodlanmagan so'zlar
  Future<List<Word>> getUnlearnedWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'is_learned = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Word.fromMap(maps[i]));
  }

  // Yodlangan so'zlar
  Future<List<Word>> getLearnedWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'is_learned = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Word.fromMap(maps[i]));
  }

  // So'z qo'shish
  Future<Word> insertWord(Word word) async {
    final db = await database;
    final id = await db.insert('words', word.toMap());
    return word.copyWith(id: id);
  }

  // So'zni yangilash
  Future<void> updateWord(Word word) async {
    final db = await database;
    await db.update(
      'words',
      word.toMap(),
      where: 'id = ?',
      whereArgs: [word.id],
    );
  }

  // So'zni o'chirish
  Future<void> deleteWord(int id) async {
    final db = await database;
    await db.delete(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Yodlandi/yodlanmadi toggle
  Future<void> toggleLearned(Word word) async {
    final updated = word.copyWith(isLearned: !word.isLearned);
    await updateWord(updated);
  }

  // Qidiruv
  Future<List<Word>> searchWords(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'uzbek LIKE ? OR english LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Word.fromMap(maps[i]));
  }
}
