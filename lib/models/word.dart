class Word {
  final int? id;
  final String uzbek;
  final String english;
  bool isLearned;
  final DateTime createdAt;

  Word({
    this.id,
    required this.uzbek,
    required this.english,
    this.isLearned = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'uzbek': uzbek,
        'english': english,
        'is_learned': isLearned ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Word.fromMap(Map<String, dynamic> map) => Word(
        id: map['id'],
        uzbek: map['uzbek'],
        english: map['english'],
        isLearned: map['is_learned'] == 1,
        createdAt: DateTime.parse(map['created_at']),
      );

  Word copyWith({int? id, String? uzbek, String? english, bool? isLearned, DateTime? createdAt}) =>
      Word(
        id: id ?? this.id,
        uzbek: uzbek ?? this.uzbek,
        english: english ?? this.english,
        isLearned: isLearned ?? this.isLearned,
        createdAt: createdAt ?? this.createdAt,
      );
}
