class ApiSearchResult {
  final int id;
  final String word;
  final String? wordClassBody;
  final List<String> translations;

  ApiSearchResult({
    required this.id,
    required this.word,
    this.wordClassBody,
    required this.translations,
  });

  factory ApiSearchResult.fromJson(Map<String, dynamic> json) {
    final uzWords = (json['words_uz'] as List<dynamic>? ?? [])
        .map((e) => e['word']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return ApiSearchResult(
      id: json['id'],
      word: json['word'] ?? '',
      wordClassBody: json['word_class_body'],
      translations: uzWords,
    );
  }
}

class ApiWordDetail {
  final int id;
  final String word;
  final String? wordClassBody;
  final String? example;
  final String? examples;
  final String? synonyms;
  final String? antonyms;
  final List<String> translations;
  final String? wordClass;
  final List<ApiWordChild> children;

  ApiWordDetail({
    required this.id,
    required this.word,
    this.wordClassBody,
    this.example,
    this.examples,
    this.synonyms,
    this.antonyms,
    required this.translations,
    this.wordClass,
    required this.children,
  });

  factory ApiWordDetail.fromJson(Map<String, dynamic> json) {
    final uzWords = (json['words_uz'] as List<dynamic>? ?? [])
        .map((e) => e['word']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final children = (json['children'] as List<dynamic>? ?? [])
        .map((e) => ApiWordChild.fromJson(e))
        .toList();
    return ApiWordDetail(
      id: json['id'],
      word: json['word'] ?? '',
      wordClassBody: json['word_class_body'],
      example: json['example'],
      examples: json['examples'],
      synonyms: json['synonyms'],
      antonyms: json['anthonims'],
      translations: uzWords,
      wordClass: json['word_class']?['class'],
      children: children,
    );
  }
}

class ApiWordChild {
  final int id;
  final String word;
  final String? example;
  final String? synonyms;
  final String? antonyms;
  final String? moreExamples;
  final List<String> translations;

  ApiWordChild({
    required this.id,
    required this.word,
    this.example,
    this.synonyms,
    this.antonyms,
    this.moreExamples,
    required this.translations,
  });

  factory ApiWordChild.fromJson(Map<String, dynamic> json) {
    final uzWords = (json['words_uz'] as List<dynamic>? ?? [])
        .map((e) => e['word']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return ApiWordChild(
      id: json['id'],
      word: json['word'] ?? '',
      example: json['example'],
      synonyms: json['synonyms'],
      antonyms: json['anthonims'],
      moreExamples: json['more_examples'],
      translations: uzWords,
    );
  }
}

class HistoryItem {
  final int wordId;
  final String word;
  final List<String> translations;
  final DateTime viewedAt;

  HistoryItem({
    required this.wordId,
    required this.word,
    required this.translations,
    required this.viewedAt,
  });

  Map<String, dynamic> toMap() => {
        'word_id': wordId,
        'word': word,
        'translations': translations.join(','),
        'viewed_at': viewedAt.toIso8601String(),
      };

  factory HistoryItem.fromMap(Map<String, dynamic> map) => HistoryItem(
        wordId: map['word_id'],
        word: map['word'],
        translations: (map['translations'] as String).split(',').where((s) => s.isNotEmpty).toList(),
        viewedAt: DateTime.parse(map['viewed_at']),
      );
}
