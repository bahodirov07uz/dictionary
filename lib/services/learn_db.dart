import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/wisdom_models.dart';

class LearnDb {
  static final LearnDb _i = LearnDb._();
  factory LearnDb() => _i;
  LearnDb._();

  Database? _db;

  Future<void> init() async {
    final path = join(await getDatabasesPath(), 'learn_words.db');
    _db = await openDatabase(path, version: 1, onCreate: _create);
  }

  Future<void> _create(Database db, int v) async {
    await db.execute('''
      CREATE TABLE learn_words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        english TEXT NOT NULL,
        uzbek TEXT NOT NULL,
        word_class TEXT,
        example TEXT,
        word_entity_id INTEGER NOT NULL DEFAULT 0,
        is_learned INTEGER NOT NULL DEFAULT 0,
        added_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE view_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_entity_id INTEGER NOT NULL UNIQUE,
        word TEXT NOT NULL,
        translations TEXT NOT NULL DEFAULT '',
        viewed_at TEXT NOT NULL
      )
    ''');
  }

  Future<List<LearnWord>> getAll() async {
    final rows = await _db!.query('learn_words', orderBy: 'added_at DESC');
    return rows.map(LearnWord.fromMap).toList();
  }

  Future<LearnWord> insert(LearnWord w) async {
    final map = w.toMap()..remove('id');
    final id = await _db!.insert('learn_words', map);
    return LearnWord(
      id: id,
      english: w.english,
      uzbek: w.uzbek,
      wordClass: w.wordClass,
      example: w.example,
      wordEntityId: w.wordEntityId,
      isLearned: w.isLearned,
      addedAt: w.addedAt,
    );
  }

  Future<bool> exists(int wordEntityId) async {
    final rows = await _db!.query('learn_words',
        where: 'word_entity_id = ?', whereArgs: [wordEntityId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> toggleLearned(int id, bool current) async {
    await _db!.update(
      'learn_words',
      {'is_learned': current ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    await _db!.delete('learn_words', where: 'id = ?', whereArgs: [id]);
  }

  // ─── HISTORY ─────────────────────────────────────────────
  Future<List<HistoryItem>> getHistory({int limit = 100}) async {
    final rows = await _db!.query('view_history',
        orderBy: 'viewed_at DESC', limit: limit);
    return rows.map(HistoryItem.fromMap).toList();
  }

  Future<void> addHistory(HistoryItem item) async {
    await _db!.insert('view_history', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHistory(int wordEntityId) async {
    await _db!.delete('view_history',
        where: 'word_entity_id = ?', whereArgs: [wordEntityId]);
  }

  Future<void> clearHistory() async {
    await _db!.delete('view_history');
  }

  // ─── IMPORT / EXPORT JSON ────────────────────────────────
  Future<String> exportJson() async {
    final words = await getAll();
    final list = words.map((w) => w.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'count': list.length,
      'words': list,
    });
  }

  Future<(int, int)> importJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final list = data['words'] as List<dynamic>;
    int imported = 0, skipped = 0;
    for (final item in list) {
      try {
        final w = LearnWord.fromJson(item as Map<String, dynamic>);
        if (await exists(w.wordEntityId)) {
          skipped++;
        } else {
          await insert(w);
          imported++;
        }
      } catch (_) {
        skipped++;
      }
    }
    return (imported, skipped);
  }

  Future<void> saveExportToFile(String path) async {
    final json = await exportJson();
    await File(path).writeAsString(json);
  }
}
