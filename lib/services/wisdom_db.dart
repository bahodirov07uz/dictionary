import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive.dart';
import '../models/wisdom_models.dart';

/// Wisdom offline DB
/// assets/wisdom.db.zip dan bir marta chiqarib ishlatadi
class WisdomDb {
  static final WisdomDb _i = WisdomDb._();
  factory WisdomDb() => _i;
  WisdomDb._();

  Database? _db;
  bool get isReady => _db != null;

  final Map<String, List<WisdomSearchResult>> _searchCache = {};

  Future<void> init() async {
    final dbsPath = await getDatabasesPath();
    final dbFile = File(join(dbsPath, 'wisdom.db'));

    // Agar DB allaqachon chiqarilgan bo'lsa, qayta chiqarmaymiz
    if (!dbFile.existsSync()) {
      final extracted = await _extractFromZip(dbFile.path);
      if (!extracted) return; // zip ham yo'q
    }

    try {
      _db = await openDatabase(dbFile.path, readOnly: true);
    } catch (_) {}
  }

  Future<bool> _extractFromZip(String destPath) async {
    try {
      // assets/wisdom.db.zip dan o'qiymiz
      final data = await rootBundle.load('assets/wisdom.db.zip');
      final bytes = data.buffer.asUint8List();

      // Unzip
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.name.endsWith('.db') && file.isFile) {
          final outFile = File(destPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // ─── SEARCH ──────────────────────────────────────────────
  Future<List<WisdomSearchResult>> search(String query) async {
    if (!isReady || query.trim().isEmpty) return [];

    final key = query.trim().toLowerCase();
    if (_searchCache.containsKey(key)) return _searchCache[key]!;

    final q = '%$key%';
    final rows = await _db!.rawQuery('''
      SELECT
        c.id, c.wordenid, c.word, c.category,
        w.word_classword_class, w.star
      FROM catalogue c
      LEFT JOIN word_entity w ON w.id = c.wordenid
      WHERE LOWER(c.word) LIKE ?
      ORDER BY
        CASE
          WHEN LOWER(c.word) = ?    THEN 0
          WHEN LOWER(c.word) LIKE ? THEN 1
          ELSE 2
        END, c.word
      LIMIT 80
    ''', [q, key, '$key%']);

    final results = <WisdomSearchResult>[];
    for (final row in rows) {
      final wordenId = (row['wordenid'] as int?) ?? 0;
      List<String> translations = [];
      if (wordenId > 0) {
        final uzRows = await _db!.query('words_uz',
            where: 'word_id = ?', whereArgs: [wordenId], limit: 3);
        translations = uzRows
            .map((r) => r['word']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      results.add(WisdomSearchResult(
        id: (row['id'] as int?) ?? 0,
        wordenId: wordenId,
        word: row['word']?.toString() ?? '',
        wordClass: row['word_classword_class']?.toString(),
        category: row['category']?.toString(),
        translations: translations,
        isStar: row['star']?.toString() == '1',
      ));
    }

    _searchCache[key] = results;
    return results;
  }

  // ─── DETAIL ──────────────────────────────────────────────
  Future<WisdomWord?> getDetail(int wordEntityId) async {
    if (!isReady) return null;

    final rows = await _db!.query('word_entity',
        where: 'id = ?', whereArgs: [wordEntityId], limit: 1);
    if (rows.isEmpty) return null;

    final row = rows.first;
    final translations = await _getTranslations(wordEntityId);
    final children = await _getChildren(wordEntityId);

    return WisdomWord(
      id: wordEntityId,
      word: row['word']?.toString() ?? '',
      wordClass: row['word_classword_class']?.toString(),
      wordClassBody: row['word_class_body']?.toString(),
      body: row['body']?.toString(),
      synonyms: row['synonyms']?.toString(),
      antonyms: row['anthonims']?.toString(),
      example: row['example']?.toString(),
      examples: row['examples']?.toString(),
      moreExamples: row['more_examples']?.toString(),
      isStar: row['star']?.toString() == '1',
      translations: translations,
      children: children,
    );
  }

  Future<List<String>> _getTranslations(int wordId) async {
    final rows = await _db!.query('words_uz',
        where: 'word_id = ?', whereArgs: [wordId], limit: 5);
    return rows
        .map((r) => r['word']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<List<WisdomWord>> _getChildren(int parentId) async {
    final rows = await _db!.query('parents',
        where: 'word_id = ?', whereArgs: [parentId]);
    final children = <WisdomWord>[];
    for (final row in rows) {
      final childId = (row['id'] as int?) ?? 0;
      final translations = await _getTranslations(childId);
      children.add(WisdomWord(
        id: childId,
        word: row['word']?.toString() ?? '',
        wordClass: row['word_classword_class']?.toString(),
        wordClassBody: row['word_class_body']?.toString(),
        synonyms: row['synonyms']?.toString(),
        antonyms: row['anthonims']?.toString(),
        example: row['example']?.toString(),
        examples: row['examples']?.toString(),
        moreExamples: row['more_examples']?.toString(),
        isStar: row['star']?.toString() == '1',
        translations: translations,
      ));
    }
    return children;
  }

  void clearCache() => _searchCache.clear();
}
