/// Represents an educational stage with Arabic and English names.
class Stage {
  final int id;
  final String nameAr;
  final String nameEn;
  final int order;
  const Stage({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.order,
  });
  factory Stage.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'ar',
  }) {
    final localizedName = _string(json['Name'] ?? json['name']);
    final arabicName = _string(json['NameAr'] ?? json['nameAr']);
    final englishName = _string(json['NameEn'] ?? json['nameEn']);
    return Stage(
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
      order: _int(json['Order'] ?? json['order']),
    );
  }
  String getName(String languageCode) {
    final preferred = languageCode == 'en' ? nameEn : nameAr;
    final fallback = languageCode == 'en' ? nameAr : nameEn;
    return preferred.trim().isNotEmpty ? preferred : fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'NameAr': nameAr,
      'NameEn': nameEn,
      'Order': order,
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

String _string(dynamic value) => value?.toString().trim() ?? '';
