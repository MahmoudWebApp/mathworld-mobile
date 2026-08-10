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
  final bool? wasCorrect;
  final int? selectedOptionId;
  final int? correctOptionId;
  final bool isFavorite;
  final int viewsCount;
  final int attemptCount;
  final bool? firstAttemptCorrect;
  final bool canRetry;
  final String masteryStatus;
  final int? bestTimeSeconds;
  final int? averageTimeSeconds;
  final bool isInErrorNotebook;
  final bool isErrorNotebookArchived;
  final DateTime? nextReviewAt;
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
    this.wasCorrect,
    this.selectedOptionId,
    this.correctOptionId,
    required this.isFavorite,
    required this.viewsCount,
    this.attemptCount = 0,
    this.firstAttemptCorrect,
    this.canRetry = false,
    this.masteryStatus = 'New',
    this.bestTimeSeconds,
    this.averageTimeSeconds,
    this.isInErrorNotebook = false,
    this.isErrorNotebookArchived = false,
    this.nextReviewAt,
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
    final wasCorrectValue = json['WasCorrect'] ?? json['wasCorrect'];

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
      wasCorrect: wasCorrectValue == null ? null : _bool(wasCorrectValue),
      selectedOptionId: _nullableInt(
        json['SelectedOptionId'] ?? json['selectedOptionId'],
      ),
      correctOptionId: _nullableInt(
        json['CorrectOptionId'] ?? json['correctOptionId'],
      ),
      isFavorite: _bool(json['IsFavorite'] ?? json['isFavorite']),
      viewsCount: _int(json['ViewsCount'] ?? json['viewsCount']),
      attemptCount: _int(json['AttemptCount'] ?? json['attemptCount']),
      firstAttemptCorrect: _nullableBool(
        json['FirstAttemptCorrect'] ?? json['firstAttemptCorrect'],
      ),
      canRetry: _bool(json['CanRetry'] ?? json['canRetry']),
      masteryStatus: _string(
        json['MasteryStatus'] ?? json['masteryStatus'] ?? 'New',
      ),
      bestTimeSeconds: _nullableInt(
        json['BestTimeSeconds'] ?? json['bestTimeSeconds'],
      ),
      averageTimeSeconds: _nullableInt(
        json['AverageTimeSeconds'] ?? json['averageTimeSeconds'],
      ),
      isInErrorNotebook: _bool(
        json['IsInErrorNotebook'] ?? json['isInErrorNotebook'],
      ),
      isErrorNotebookArchived: _bool(
        json['IsErrorNotebookArchived'] ?? json['isErrorNotebookArchived'],
      ),
      nextReviewAt: _dateTime(json['NextReviewAt'] ?? json['nextReviewAt']),
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
    bool? wasCorrect,
    int? selectedOptionId,
    int? correctOptionId,
    bool? isFavorite,
    int? attemptCount,
    bool? firstAttemptCorrect,
    bool? canRetry,
    String? masteryStatus,
    int? bestTimeSeconds,
    int? averageTimeSeconds,
    bool? isInErrorNotebook,
    bool? isErrorNotebookArchived,
    DateTime? nextReviewAt,
    bool clearNextReviewAt = false,
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
      wasCorrect: wasCorrect ?? this.wasCorrect,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      correctOptionId: correctOptionId ?? this.correctOptionId,
      isFavorite: isFavorite ?? this.isFavorite,
      viewsCount: viewsCount ?? this.viewsCount,
      attemptCount: attemptCount ?? this.attemptCount,
      firstAttemptCorrect: firstAttemptCorrect ?? this.firstAttemptCorrect,
      canRetry: canRetry ?? this.canRetry,
      masteryStatus: masteryStatus ?? this.masteryStatus,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      averageTimeSeconds: averageTimeSeconds ?? this.averageTimeSeconds,
      isInErrorNotebook: isInErrorNotebook ?? this.isInErrorNotebook,
      isErrorNotebookArchived:
          isErrorNotebookArchived ?? this.isErrorNotebookArchived,
      nextReviewAt:
          clearNextReviewAt ? null : (nextReviewAt ?? this.nextReviewAt),
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
  final int attemptId;
  final int attemptNumber;
  final bool isOfficialAttempt;
  final bool? firstAttemptCorrect;
  final int attemptTimeSeconds;
  final int? bestTimeSeconds;
  final int totalAttempts;
  final bool canRetry;
  final String masteryStatus;
  final bool isInErrorNotebook;
  final DateTime? nextReviewAt;

  const AnswerResult({
    required this.isCorrect,
    required this.isSolved,
    required this.pointsEarned,
    this.selectedOptionId,
    this.correctOptionId,
    this.correctOptionText,
    required this.detailedSolution,
    this.youtubeSolutionUrl,
    this.attemptId = 0,
    this.attemptNumber = 0,
    this.isOfficialAttempt = false,
    this.firstAttemptCorrect,
    this.attemptTimeSeconds = 0,
    this.bestTimeSeconds,
    this.totalAttempts = 0,
    this.canRetry = false,
    this.masteryStatus = 'New',
    this.isInErrorNotebook = false,
    this.nextReviewAt,
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
      attemptId: _int(json['AttemptId'] ?? json['attemptId']),
      attemptNumber: _int(json['AttemptNumber'] ?? json['attemptNumber']),
      isOfficialAttempt: _bool(
        json['IsOfficialAttempt'] ?? json['isOfficialAttempt'],
      ),
      firstAttemptCorrect: _nullableBool(
        json['FirstAttemptCorrect'] ?? json['firstAttemptCorrect'],
      ),
      attemptTimeSeconds: _int(
        json['AttemptTimeSeconds'] ?? json['attemptTimeSeconds'],
      ),
      bestTimeSeconds: _nullableInt(
        json['BestTimeSeconds'] ?? json['bestTimeSeconds'],
      ),
      totalAttempts: _int(json['TotalAttempts'] ?? json['totalAttempts']),
      canRetry: _bool(json['CanRetry'] ?? json['canRetry']),
      masteryStatus: _string(
        json['MasteryStatus'] ?? json['masteryStatus'] ?? 'New',
      ),
      isInErrorNotebook: _bool(
        json['IsInErrorNotebook'] ?? json['isInErrorNotebook'],
      ),
      nextReviewAt: _dateTime(json['NextReviewAt'] ?? json['nextReviewAt']),
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
    int? attemptId,
    int? attemptNumber,
    bool? isOfficialAttempt,
    bool? firstAttemptCorrect,
    int? attemptTimeSeconds,
    int? bestTimeSeconds,
    int? totalAttempts,
    bool? canRetry,
    String? masteryStatus,
    bool? isInErrorNotebook,
    DateTime? nextReviewAt,
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
      attemptId: attemptId ?? this.attemptId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      isOfficialAttempt: isOfficialAttempt ?? this.isOfficialAttempt,
      firstAttemptCorrect: firstAttemptCorrect ?? this.firstAttemptCorrect,
      attemptTimeSeconds: attemptTimeSeconds ?? this.attemptTimeSeconds,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      canRetry: canRetry ?? this.canRetry,
      masteryStatus: masteryStatus ?? this.masteryStatus,
      isInErrorNotebook: isInErrorNotebook ?? this.isInErrorNotebook,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    );
  }
}

/// Represents one recorded attempt for a problem.
class ProblemAttempt {
  final int id;
  final int attemptNumber;
  final bool isOfficial;
  final int selectedOptionId;
  final String selectedOptionText;
  final int? correctOptionId;
  final String? correctOptionText;
  final bool isCorrect;
  final int timeSpentSeconds;
  final int pointsEarned;
  final bool usedHint;
  final DateTime? startedAt;
  final DateTime? submittedAt;

  const ProblemAttempt({
    required this.id,
    required this.attemptNumber,
    required this.isOfficial,
    required this.selectedOptionId,
    required this.selectedOptionText,
    this.correctOptionId,
    this.correctOptionText,
    required this.isCorrect,
    required this.timeSpentSeconds,
    required this.pointsEarned,
    required this.usedHint,
    this.startedAt,
    this.submittedAt,
  });

  factory ProblemAttempt.fromJson(Map<String, dynamic> json) {
    return ProblemAttempt(
      id: _int(json['Id'] ?? json['id']),
      attemptNumber: _int(json['AttemptNumber'] ?? json['attemptNumber']),
      isOfficial: _bool(json['IsOfficial'] ?? json['isOfficial']),
      selectedOptionId: _int(
        json['SelectedOptionId'] ?? json['selectedOptionId'],
      ),
      selectedOptionText: _string(
        json['SelectedOptionText'] ?? json['selectedOptionText'],
      ),
      correctOptionId: _nullableInt(
        json['CorrectOptionId'] ?? json['correctOptionId'],
      ),
      correctOptionText: _nullableString(
        json['CorrectOptionText'] ?? json['correctOptionText'],
      ),
      isCorrect: _bool(json['IsCorrect'] ?? json['isCorrect']),
      timeSpentSeconds: _int(
        json['TimeSpentSeconds'] ?? json['timeSpentSeconds'],
      ),
      pointsEarned: _int(json['PointsEarned'] ?? json['pointsEarned']),
      usedHint: _bool(json['UsedHint'] ?? json['usedHint']),
      startedAt: _dateTime(json['StartedAt'] ?? json['startedAt']),
      submittedAt: _dateTime(json['SubmittedAt'] ?? json['submittedAt']),
    );
  }
}

/// Represents the complete learning history for one problem.
class ProblemAttemptHistory {
  final int problemId;
  final int totalAttempts;
  final bool? firstAttemptCorrect;
  final bool isSolved;
  final int? bestTimeSeconds;
  final int? averageTimeSeconds;
  final String masteryStatus;
  final bool isInErrorNotebook;
  final bool isErrorNotebookArchived;
  final DateTime? nextReviewAt;
  final List<ProblemAttempt> attempts;

  const ProblemAttemptHistory({
    required this.problemId,
    required this.totalAttempts,
    this.firstAttemptCorrect,
    required this.isSolved,
    this.bestTimeSeconds,
    this.averageTimeSeconds,
    required this.masteryStatus,
    required this.isInErrorNotebook,
    required this.isErrorNotebookArchived,
    this.nextReviewAt,
    required this.attempts,
  });

  factory ProblemAttemptHistory.fromJson(Map<String, dynamic> json) {
    return ProblemAttemptHistory(
      problemId: _int(json['ProblemId'] ?? json['problemId']),
      totalAttempts: _int(json['TotalAttempts'] ?? json['totalAttempts']),
      firstAttemptCorrect: _nullableBool(
        json['FirstAttemptCorrect'] ?? json['firstAttemptCorrect'],
      ),
      isSolved: _bool(json['IsSolved'] ?? json['isSolved']),
      bestTimeSeconds: _nullableInt(
        json['BestTimeSeconds'] ?? json['bestTimeSeconds'],
      ),
      averageTimeSeconds: _nullableInt(
        json['AverageTimeSeconds'] ?? json['averageTimeSeconds'],
      ),
      masteryStatus: _string(
        json['MasteryStatus'] ?? json['masteryStatus'],
      ),
      isInErrorNotebook: _bool(
        json['IsInErrorNotebook'] ?? json['isInErrorNotebook'],
      ),
      isErrorNotebookArchived: _bool(
        json['IsErrorNotebookArchived'] ?? json['isErrorNotebookArchived'],
      ),
      nextReviewAt: _dateTime(json['NextReviewAt'] ?? json['nextReviewAt']),
      attempts: _list(json['Attempts'] ?? json['attempts'])
          .map((item) => ProblemAttempt.fromJson(_map(item)))
          .toList(),
    );
  }
}

/// Represents one item in the user's error notebook.
class ErrorNotebookProblem {
  final int id;
  final String title;
  final int stageId;
  final String stageName;
  final int categoryId;
  final String categoryName;
  final int attemptCount;
  final int incorrectAttempts;
  final int correctAttempts;
  final String masteryStatus;
  final bool isArchived;
  final DateTime? nextReviewAt;
  final DateTime? lastAttemptAt;

  const ErrorNotebookProblem({
    required this.id,
    required this.title,
    required this.stageId,
    required this.stageName,
    required this.categoryId,
    required this.categoryName,
    required this.attemptCount,
    required this.incorrectAttempts,
    required this.correctAttempts,
    required this.masteryStatus,
    required this.isArchived,
    this.nextReviewAt,
    this.lastAttemptAt,
  });

  factory ErrorNotebookProblem.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'ar',
  }) {
    return ErrorNotebookProblem(
      id: _int(json['Id'] ?? json['id']),
      title: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'Title',
        arabicKey: 'TitleAr',
        englishKey: 'TitleEn',
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
      attemptCount: _int(json['AttemptCount'] ?? json['attemptCount']),
      incorrectAttempts: _int(
        json['IncorrectAttempts'] ?? json['incorrectAttempts'],
      ),
      correctAttempts: _int(
        json['CorrectAttempts'] ?? json['correctAttempts'],
      ),
      masteryStatus: _string(
        json['MasteryStatus'] ?? json['masteryStatus'],
      ),
      isArchived: _bool(json['IsArchived'] ?? json['isArchived']),
      nextReviewAt: _dateTime(json['NextReviewAt'] ?? json['nextReviewAt']),
      lastAttemptAt: _dateTime(
        json['LastAttemptAt'] ?? json['lastAttemptAt'],
      ),
    );
  }

  ErrorNotebookProblem copyWith({
    bool? isArchived,
  }) {
    return ErrorNotebookProblem(
      id: id,
      title: title,
      stageId: stageId,
      stageName: stageName,
      categoryId: categoryId,
      categoryName: categoryName,
      attemptCount: attemptCount,
      incorrectAttempts: incorrectAttempts,
      correctAttempts: correctAttempts,
      masteryStatus: masteryStatus,
      isArchived: isArchived ?? this.isArchived,
      nextReviewAt: nextReviewAt,
      lastAttemptAt: lastAttemptAt,
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

bool? _nullableBool(dynamic value) {
  if (value == null) {
    return null;
  }
  return _bool(value);
}

DateTime? _dateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
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
