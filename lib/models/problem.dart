/// Represents a complete localized math problem.
class Problem {
  final int id;
  final String title;
  final String questionText;
  final int stageId;
  final String stageName;
  final int categoryId;
  final String categoryName;
  final String? categoryIcon;
  final int points;
  final bool isSolved;
  final bool hasAttempted;
  final bool isFavorite;
  final int viewsCount;
  final List<Option> options;
  final String? detailedSolution;
  final String? youtubeSolutionUrl;

  const Problem({
    required this.id,
    required this.title,
    required this.questionText,
    required this.stageId,
    required this.stageName,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.points,
    required this.isSolved,
    required this.hasAttempted,
    required this.isFavorite,
    required this.viewsCount,
    required this.options,
    this.detailedSolution,
    this.youtubeSolutionUrl,
  });

  factory Problem.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'ar',
  }) {
    final isSolved = _bool(json['IsSolved'] ?? json['isSolved']);
    final hasAttemptedValue = json['HasAttempted'] ??
        json['hasAttempted'] ??
        json['AlreadyAttempted'] ??
        json['alreadyAttempted'];

    return Problem(
      id: _int(json['Id'] ?? json['id']),
      title: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'Title',
        arabicKey: 'TitleAr',
        englishKey: 'TitleEn',
      ),
      questionText: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'QuestionText',
        arabicKey: 'QuestionTextAr',
        englishKey: 'QuestionTextEn',
      ),
      stageId: _int(json['StageId'] ?? json['stageId']),
      stageName: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'StageName',
        arabicKey: 'StageNameAr',
        englishKey: 'StageNameEn',
      ),
      categoryId: _int(json['CategoryId'] ?? json['categoryId']),
      categoryName: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'CategoryName',
        arabicKey: 'CategoryNameAr',
        englishKey: 'CategoryNameEn',
      ),
      categoryIcon: _nullableString(
        json['CategoryIcon'] ?? json['categoryIcon'],
      ),
      points: _int(json['Points'] ?? json['points']),
      isSolved: isSolved,
      hasAttempted:
          hasAttemptedValue == null ? isSolved : _bool(hasAttemptedValue),
      isFavorite: _bool(json['IsFavorite'] ?? json['isFavorite']),
      viewsCount: _int(json['ViewsCount'] ?? json['viewsCount']),
      options: _list(json['Options'] ?? json['options'])
          .map((item) => Option.fromJson(_map(item)))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      detailedSolution: localizedNullableString(
        json,
        languageCode: languageCode,
        localizedKey: 'DetailedSolution',
        arabicKey: 'DetailedSolutionAr',
        englishKey: 'DetailedSolutionEn',
      ),
      youtubeSolutionUrl: _nullableString(
        json['YoutubeSolutionUrl'] ?? json['youtubeSolutionUrl'],
      ),
    );
  }

  Problem copyWith({
    bool? isSolved,
    bool? hasAttempted,
    bool? isFavorite,
    String? detailedSolution,
    String? youtubeSolutionUrl,
    int? viewsCount,
  }) {
    return Problem(
      id: id,
      title: title,
      questionText: questionText,
      stageId: stageId,
      stageName: stageName,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      points: points,
      isSolved: isSolved ?? this.isSolved,
      hasAttempted: hasAttempted ?? this.hasAttempted,
      isFavorite: isFavorite ?? this.isFavorite,
      viewsCount: viewsCount ?? this.viewsCount,
      options: options,
      detailedSolution: detailedSolution ?? this.detailedSolution,
      youtubeSolutionUrl: youtubeSolutionUrl ?? this.youtubeSolutionUrl,
    );
  }
}

/// Represents a selectable answer option without revealing correctness.
class Option {
  final int id;
  final String latexCode;
  final int order;

  const Option({
    required this.id,
    required this.latexCode,
    required this.order,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: _int(json['Id'] ?? json['id']),
      latexCode: _string(json['LatexCode'] ?? json['latexCode']),
      order: _int(json['Order'] ?? json['order']),
    );
  }
}

/// Represents a localized problem preview used in lists.
class ProblemPreview {
  final int id;
  final String title;
  final int stageId;
  final String? stageName;
  final int categoryId;
  final String categoryName;
  final int viewsCount;
  final int points;
  final bool isSolved;
  final bool isFavorite;

  const ProblemPreview({
    required this.id,
    required this.title,
    required this.stageId,
    this.stageName,
    required this.categoryId,
    required this.categoryName,
    required this.viewsCount,
    required this.points,
    this.isSolved = false,
    this.isFavorite = false,
  });

  factory ProblemPreview.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'ar',
  }) {
    return ProblemPreview(
      id: _int(json['Id'] ?? json['id']),
      title: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'Title',
        arabicKey: 'TitleAr',
        englishKey: 'TitleEn',
      ),
      stageId: _int(json['StageId'] ?? json['stageId']),
      stageName: localizedNullableString(
        json,
        languageCode: languageCode,
        localizedKey: 'StageName',
        arabicKey: 'StageNameAr',
        englishKey: 'StageNameEn',
      ),
      categoryId: _int(json['CategoryId'] ?? json['categoryId']),
      categoryName: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'CategoryName',
        arabicKey: 'CategoryNameAr',
        englishKey: 'CategoryNameEn',
      ),
      viewsCount: _int(json['ViewsCount'] ?? json['viewsCount']),
      points: _int(json['Points'] ?? json['points']),
      isSolved: _bool(json['IsSolved'] ?? json['isSolved']),
      isFavorite: _bool(json['IsFavorite'] ?? json['isFavorite']),
    );
  }
}

/// Represents the server response returned after answer submission.
class AnswerResult {
  final bool isCorrect;
  final bool isSolved;
  final int pointsEarned;
  final int? selectedOptionId;
  final int? correctOptionId;
  final String? correctOptionText;
  final String detailedSolution;
  final String? youtubeSolutionUrl;

  const AnswerResult({
    required this.isCorrect,
    required this.isSolved,
    required this.pointsEarned,
    this.selectedOptionId,
    this.correctOptionId,
    this.correctOptionText,
    required this.detailedSolution,
    this.youtubeSolutionUrl,
  });

  factory AnswerResult.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'ar',
  }) {
    final isCorrect = _bool(json['IsCorrect'] ?? json['isCorrect']);

    return AnswerResult(
      isCorrect: isCorrect,
      isSolved: json.containsKey('IsSolved') || json.containsKey('isSolved')
          ? _bool(json['IsSolved'] ?? json['isSolved'])
          : isCorrect,
      pointsEarned: _int(json['PointsEarned'] ?? json['pointsEarned']),
      selectedOptionId: _nullableInt(
        json['SelectedOptionId'] ?? json['selectedOptionId'],
      ),
      correctOptionId: _nullableInt(
        json['CorrectOptionId'] ?? json['correctOptionId'],
      ),
      correctOptionText: _nullableString(
        json['CorrectOptionText'] ?? json['correctOptionText'],
      ),
      detailedSolution: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'DetailedSolution',
        arabicKey: 'DetailedSolutionAr',
        englishKey: 'DetailedSolutionEn',
      ),
      youtubeSolutionUrl: _nullableString(
        json['YoutubeSolutionUrl'] ?? json['youtubeSolutionUrl'],
      ),
    );
  }

  AnswerResult copyWith({
    bool? isCorrect,
    bool? isSolved,
    int? pointsEarned,
    int? selectedOptionId,
    int? correctOptionId,
    String? correctOptionText,
    String? detailedSolution,
    String? youtubeSolutionUrl,
  }) {
    return AnswerResult(
      isCorrect: isCorrect ?? this.isCorrect,
      isSolved: isSolved ?? this.isSolved,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      correctOptionId: correctOptionId ?? this.correctOptionId,
      correctOptionText: correctOptionText ?? this.correctOptionText,
      detailedSolution: detailedSolution ?? this.detailedSolution,
      youtubeSolutionUrl: youtubeSolutionUrl ?? this.youtubeSolutionUrl,
    );
  }
}

String localizedString(
  Map<String, dynamic> json, {
  required String languageCode,
  required String localizedKey,
  required String arabicKey,
  required String englishKey,
}) {
  return localizedNullableString(
        json,
        languageCode: languageCode,
        localizedKey: localizedKey,
        arabicKey: arabicKey,
        englishKey: englishKey,
      ) ??
      '';
}

String? localizedNullableString(
  Map<String, dynamic> json, {
  required String languageCode,
  required String localizedKey,
  required String arabicKey,
  required String englishKey,
}) {
  final preferredKey = languageCode == 'en' ? englishKey : arabicKey;
  final fallbackKey = languageCode == 'en' ? arabicKey : englishKey;
  final candidates = [
    json[preferredKey],
    json[localizedKey],
    json[_lowerCamel(localizedKey)],
    json[localizedKey.toLowerCase()],
    json[fallbackKey],
  ];

  for (final candidate in candidates) {
    final value = _nullableString(candidate);
    if (value != null) {
      return value;
    }
  }

  return null;
}

String _lowerCamel(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toLowerCase()}${value.substring(1)}';
}

Map<String, dynamic> _map(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : const {};
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

int _int(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

bool _bool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

String _string(dynamic value) => value?.toString().trim() ?? '';

String? _nullableString(dynamic value) {
  final result = _string(value);
  return result.isEmpty ? null : result;
}
