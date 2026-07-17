/// Represents a problem category within an educational stage.
class Category {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? icon;
  final int stageId;
  final int order;
  final int? problemsCount;
  final int? solvedCount;
  const Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.icon,
    required this.stageId,
    required this.order,
    this.problemsCount,
    this.solvedCount,
  });
  factory Category.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'ar',
  }) {
    final localizedName = _string(json['Name'] ?? json['name']);
    final arabicName = _string(json['NameAr'] ?? json['nameAr']);
    final englishName = _string(json['NameEn'] ?? json['nameEn']);
    return Category(
      id: _int(json['Id'] ?? json['id']),
      nameAr: arabicName.isNotEmpty
          ? arabicName
          : languageCode == 'ar'
              ? localizedName
              : englishName,
      nameEn: englishName.isNotEmpty
          ? englishName
          : languageCode == 'en'
              ? localizedName
              : arabicName,
      icon: _nullableString(json['Icon'] ?? json['icon']),
      stageId: _int(json['StageId'] ?? json['stageId']),
      order: _int(json['Order'] ?? json['order']),
      problemsCount: _nullableInt(
        json['ProblemsCount'] ?? json['problemsCount'],
      ),
      solvedCount: _nullableInt(json['SolvedCount'] ?? json['solvedCount']),
    );
  }
  String getName(String languageCode) {
    final preferred = languageCode == 'en' ? nameEn : nameAr;
    final fallback = languageCode == 'en' ? nameAr : nameEn;
    return preferred.trim().isNotEmpty ? preferred : fallback;
  }

  double? get progress {
    if (problemsCount == null || problemsCount == 0 || solvedCount == null) {
      return null;
    }
    return (solvedCount! / problemsCount!).clamp(0.0, 1.0).toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'NameAr': nameAr,
      'NameEn': nameEn,
      'Icon': icon,
      'StageId': stageId,
      'Order': order,
      'ProblemsCount': problemsCount,
      'SolvedCount': solvedCount,
    };
  }
}

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

String _string(dynamic value) => value?.toString().trim() ?? '';
String? _nullableString(dynamic value) {
  final result = _string(value);
  return result.isEmpty ? null : result;
}
