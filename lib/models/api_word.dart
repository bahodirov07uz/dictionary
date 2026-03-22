class ApiSearchResult {
  final int id;
  final String word;
  final String? wordClass;
  final String? wordClassBody;
  final List<String> translations;
  final bool isStar;

  ApiSearchResult({
    required this.id,
    required this.word,
    this.wordClass,
    this.wordClassBody,
    required this.translations,
    this.isStar = false,
  });

  factory ApiSearchResult.fromJson(Map<String, dynamic> json) {
    final uzWords = (json['words_uz'] as List<dynamic>? ?? [])
        .map((e) => e['word']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final wc = json['word_class'];
    String? cls;
    if (wc is Map) cls = wc['class']?.toString();

    return ApiSearchResult(
      id: json['id'],
      word: json['word'] ?? '',
      wordClass: cls,
      wordClassBody: json['word_class_body']?.toString(),
      translations: uzWords,
      isStar: (json['star'] ?? 0) == 1,
    );
  }
}

class ApiWordDetail {
  final int id;
  final String word;
  final String? wordClass;
  final String? wordClassBody;
  final String? example;
  final String? examples;
  final String? synonyms;
  final String? antonyms;
  final List<String> translations;
  final List<ApiWordChild> children;
  final bool isStar;

  ApiWordDetail({
    required this.id,
    required this.word,
    this.wordClass,
    this.wordClassBody,
    this.example,
    this.examples,
    this.synonyms,
    this.antonyms,
    required this.translations,
    required this.children,
    this.isStar = false,
  });

  factory ApiWordDetail.fromJson(Map<String, dynamic> json) {
    final uzWords = (json['words_uz'] as List<dynamic>? ?? [])
        .map((e) => e['word']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final children = (json['children'] as List<dynamic>? ?? [])
        .map((e) => ApiWordChild.fromJson(e))
        .toList();
    final wc = json['word_class'];
    String? cls;
    if (wc is Map) cls = wc['class']?.toString();

    return ApiWordDetail(
      id: json['id'],
      word: json['word'] ?? '',
      wordClass: cls,
      wordClassBody: json['word_class_body']?.toString(),
      example: json['example']?.toString(),
      examples: json['examples']?.toString(),
      synonyms: json['synonyms']?.toString(),
      antonyms: json['anthonims']?.toString(),
      translations: uzWords,
      children: children,
      isStar: (json['star'] ?? 0) == 1,
    );
  }
}

class ApiWordChild {
  final int id;
  final String word;
  final String? wordClass;
  final String? example;
  final String? examples;
  final String? moreExamples;
  final String? synonyms;
  final String? antonyms;
  final List<String> translations;

  ApiWordChild({
    required this.id,
    required this.word,
    this.wordClass,
    this.example,
    this.examples,
    this.moreExamples,
    this.synonyms,
    this.antonyms,
    required this.translations,
  });

  factory ApiWordChild.fromJson(Map<String, dynamic> json) {
    final uzWords = (json['words_uz'] as List<dynamic>? ?? [])
        .map((e) => e['word']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final wc = json['word_class'];
    String? cls;
    if (wc is Map) cls = wc['class']?.toString();
    return ApiWordChild(
      id: json['id'],
      word: json['word'] ?? '',
      wordClass: cls,
      example: json['example']?.toString(),
      examples: json['examples']?.toString(),
      moreExamples: json['more_examples']?.toString(),
      synonyms: json['synonyms']?.toString(),
      antonyms: json['anthonims']?.toString(),
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
