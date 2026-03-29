class WisdomWord {
  final int id;
  final String word;
  final String? wordClass;
  final String? wordClassBody;
  final String? body;
  final String? synonyms;
  final String? antonyms;
  final String? example;
  final String? examples;
  final String? moreExamples;
  final bool isStar;
  final List<String> translations;
  final List<WisdomWord> children;

  WisdomWord({
    required this.id,
    required this.word,
    this.wordClass,
    this.wordClassBody,
    this.body,
    this.synonyms,
    this.antonyms,
    this.example,
    this.examples,
    this.moreExamples,
    this.isStar = false,
    this.translations = const [],
    this.children = const [],
  });
}

class WisdomSearchResult {
  final int id;
  final int wordenId;
  final String word;
  final String? wordClass;
  final String? category;
  final List<String> translations;
  final bool isStar;

  WisdomSearchResult({
    required this.id,
    required this.wordenId,
    required this.word,
    this.wordClass,
    this.category,
    this.translations = const [],
    this.isStar = false,
  });
}

// Yodlash uchun so'z (import/export JSON)
class LearnWord {
  final int? id;
  final String english;      // word_entity.word
  final String uzbek;        // words_uz birinchi tarjima
  final String? wordClass;
  final String? example;
  final int wordEntityId;    // Wisdom DB dagi id
  bool isLearned;
  final DateTime addedAt;

  LearnWord({
    this.id,
    required this.english,
    required this.uzbek,
    this.wordClass,
    this.example,
    required this.wordEntityId,
    this.isLearned = false,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'english': english,
    'uzbek': uzbek,
    'word_class': wordClass,
    'example': example,
    'word_entity_id': wordEntityId,
    'is_learned': isLearned ? 1 : 0,
    'added_at': addedAt.toIso8601String(),
  };

  factory LearnWord.fromMap(Map<String, dynamic> m) => LearnWord(
    id: m['id'] as int?,
    english: m['english'] as String,
    uzbek: m['uzbek'] as String,
    wordClass: m['word_class'] as String?,
    example: m['example'] as String?,
    wordEntityId: m['word_entity_id'] as int,
    isLearned: (m['is_learned'] as int) == 1,
    addedAt: DateTime.parse(m['added_at'] as String),
  );

  // JSON import/export
  Map<String, dynamic> toJson() => {
    'english': english,
    'uzbek': uzbek,
    'word_class': wordClass,
    'example': example,
    'word_entity_id': wordEntityId,
    'is_learned': isLearned,
    'added_at': addedAt.toIso8601String(),
  };

  factory LearnWord.fromJson(Map<String, dynamic> j) => LearnWord(
    english: j['english'] as String,
    uzbek: j['uzbek'] as String,
    wordClass: j['word_class'] as String?,
    example: j['example'] as String?,
    wordEntityId: j['word_entity_id'] as int,
    isLearned: j['is_learned'] as bool? ?? false,
    addedAt: j['added_at'] != null ? DateTime.parse(j['added_at']) : DateTime.now(),
  );

  LearnWord copyWith({bool? isLearned}) => LearnWord(
    id: id,
    english: english,
    uzbek: uzbek,
    wordClass: wordClass,
    example: example,
    wordEntityId: wordEntityId,
    isLearned: isLearned ?? this.isLearned,
    addedAt: addedAt,
  );
}

class HistoryItem {
  final int wordEntityId;
  final String word;
  final List<String> translations;
  final DateTime viewedAt;

  HistoryItem({
    required this.wordEntityId,
    required this.word,
    required this.translations,
    required this.viewedAt,
  });

  Map<String, dynamic> toMap() => {
    'word_entity_id': wordEntityId,
    'word': word,
    'translations': translations.join('|'),
    'viewed_at': viewedAt.toIso8601String(),
  };

  factory HistoryItem.fromMap(Map<String, dynamic> m) => HistoryItem(
    wordEntityId: m['word_entity_id'] as int,
    word: m['word'] as String,
    translations: (m['translations'] as String).split('|').where((s) => s.isNotEmpty).toList(),
    viewedAt: DateTime.parse(m['viewed_at'] as String),
  );
}
