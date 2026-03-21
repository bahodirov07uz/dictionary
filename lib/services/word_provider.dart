import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../services/database_service.dart';

class WordProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Word> _allWords = [];
  List<Word> _filteredWords = [];
  String _searchQuery = '';
  FilterType _filterType = FilterType.all;
  bool _isLoading = false;

  List<Word> get words => _filteredWords;
  bool get isLoading => _isLoading;
  FilterType get filterType => _filterType;
  String get searchQuery => _searchQuery;

  int get totalCount => _allWords.length;
  int get learnedCount => _allWords.where((w) => w.isLearned).length;
  int get unlearnedCount => _allWords.where((w) => !w.isLearned).length;

  Future<void> loadWords() async {
    _isLoading = true;
    notifyListeners();

    _allWords = await _db.getAllWords();
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  void _applyFilters() {
    List<Word> filtered = _allWords;

    // Filter type
    if (_filterType == FilterType.learned) {
      filtered = filtered.where((w) => w.isLearned).toList();
    } else if (_filterType == FilterType.unlearned) {
      filtered = filtered.where((w) => !w.isLearned).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((w) =>
              w.uzbek.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              w.english.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    _filteredWords = filtered;
  }

  void setFilter(FilterType type) {
    _filterType = type;
    _applyFilters();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  Future<void> addWord(String uzbek, String english) async {
    final word = Word(uzbek: uzbek, english: english);
    final saved = await _db.insertWord(word);
    _allWords.insert(0, saved);
    _applyFilters();
    notifyListeners();
  }

  Future<void> toggleLearned(Word word) async {
    await _db.toggleLearned(word);
    final index = _allWords.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      _allWords[index] = word.copyWith(isLearned: !word.isLearned);
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> deleteWord(Word word) async {
    await _db.deleteWord(word.id!);
    _allWords.removeWhere((w) => w.id == word.id);
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateWord(Word word, String uzbek, String english) async {
    final updated = word.copyWith(uzbek: uzbek, english: english);
    await _db.updateWord(updated);
    final index = _allWords.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      _allWords[index] = updated;
      _applyFilters();
      notifyListeners();
    }
  }
}

enum FilterType { all, learned, unlearned }
