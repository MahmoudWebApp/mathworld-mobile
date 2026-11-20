/// Represents an educational stage with Arabic and English names.
class Stage {
  final int id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final int order;
  const Stage({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr = '',
    this.descriptionEn = '',
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
      descriptionAr: _string(json['DescriptionAr'] ?? json['descriptionAr']),
      descriptionEn: _string(json['DescriptionEn'] ?? json['descriptionEn']),
      order: _int(json['Order'] ?? json['order']),
    );
  }
  String getName(String languageCode) {
    final preferred = languageCode == 'en' ? nameEn : nameAr;
    final fallback = languageCode == 'en' ? nameAr : nameEn;
    return preferred.trim().isNotEmpty ? preferred : fallback;
  }

  String getDescription(String languageCode) =>
      languageCode == 'en' ? descriptionEn : descriptionAr;

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'NameAr': nameAr,
      'NameEn': nameEn,
      'DescriptionAr': descriptionAr,
      'DescriptionEn': descriptionEn,
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
