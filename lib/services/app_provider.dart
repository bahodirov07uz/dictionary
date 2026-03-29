import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/wisdom_models.dart';
import 'wisdom_db.dart';
import 'learn_db.dart';

class AppProvider extends ChangeNotifier {
  final _wisdom = WisdomDb();
  final _learn = LearnDb();

  bool _ready = false;
  bool get ready => _ready;
  bool get wisdomReady => _wisdom.isReady;

  // Learn words
  List<LearnWord> _all = [];
  FilterType _filter = FilterType.all;
  String _localSearch = '';

  List<LearnWord> get words {
    var list = _filter == FilterType.learned
        ? _all.where((w) => w.isLearned).toList()
        : _filter == FilterType.unlearned
            ? _all.where((w) => !w.isLearned).toList()
            : List<LearnWord>.from(_all);
    if (_localSearch.isNotEmpty) {
      final q = _localSearch.toLowerCase();
      list = list.where((w) =>
          w.english.toLowerCase().contains(q) ||
          w.uzbek.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  FilterType get filter => _filter;
  int get totalCount => _all.length;
  int get learnedCount => _all.where((w) => w.isLearned).length;
  int get unlearnedCount => _all.where((w) => !w.isLearned).length;

  // History
  List<HistoryItem> _history = [];
  List<HistoryItem> get history => _history;

  Future<void> init() async {
    await _wisdom.init();
    await _learn.init();
    await _loadWords();
    _history = await _learn.getHistory();
    _ready = true;
    notifyListeners();
  }

  Future<void> _loadWords() async {
    _all = await _learn.getAll();
  }

  // ─── FILTER / SEARCH ─────────────────────────────────────
  void setFilter(FilterType f) { _filter = f; notifyListeners(); }
  void setLocalSearch(String q) { _localSearch = q; notifyListeners(); }

  // ─── WORD ACTIONS ─────────────────────────────────────────
  Future<bool> addWord(LearnWord w) async {
    if (await _learn.exists(w.wordEntityId)) return false;
    final saved = await _learn.insert(w);
    _all.insert(0, saved);
    notifyListeners();
    return true;
  }

  Future<void> toggleLearned(LearnWord w) async {
    await _learn.toggleLearned(w.id!, w.isLearned);
    final i = _all.indexWhere((x) => x.id == w.id);
    if (i != -1) {
      _all[i] = _all[i].copyWith(isLearned: !w.isLearned);
      notifyListeners();
    }
  }

  Future<void> deleteWord(LearnWord w) async {
    await _learn.delete(w.id!);
    _all.removeWhere((x) => x.id == w.id);
    notifyListeners();
  }

  Future<bool> wordExists(int wordEntityId) => _learn.exists(wordEntityId);

  // ─── SEARCH (Wisdom DB) ──────────────────────────────────
  Future<List<WisdomSearchResult>> search(String query) =>
      _wisdom.search(query);

  // ─── DETAIL (Wisdom DB) ──────────────────────────────────
  Future<WisdomWord?> getDetail(int wordEntityId) =>
      _wisdom.getDetail(wordEntityId);

  // ─── HISTORY ─────────────────────────────────────────────
  Future<void> addHistory(HistoryItem item) async {
    await _learn.addHistory(item);
    _history.removeWhere((h) => h.wordEntityId == item.wordEntityId);
    _history.insert(0, item);
    notifyListeners();
  }

  Future<void> deleteHistory(int wordEntityId) async {
    await _learn.deleteHistory(wordEntityId);
    _history.removeWhere((h) => h.wordEntityId == wordEntityId);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _learn.clearHistory();
    _history.clear();
    notifyListeners();
  }

  // ─── IMPORT / EXPORT ─────────────────────────────────────
  Future<String> exportPath() async {
    final dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    return '${dir.path}/lughatim_export_${DateTime.now().millisecondsSinceEpoch}.json';
  }

  Future<String> exportToFile() async {
    final path = await exportPath();
    await _learn.saveExportToFile(path);
    return path;
  }

  Future<(int, int)> importFromFile(String path) async {
    final content = await File(path).readAsString();
    final result = await _learn.importJson(content);
    await _loadWords();
    notifyListeners();
    return result;
  }

  Future<(int, int)> importFromJson(String jsonStr) async {
    final result = await _learn.importJson(jsonStr);
    await _loadWords();
    notifyListeners();
    return result;
  }
}

enum FilterType { all, learned, unlearned }
