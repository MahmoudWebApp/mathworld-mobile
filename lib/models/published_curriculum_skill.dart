/// Public mathematical objective metadata; never contains a problem answer.
class PublishedCurriculumSkill {
  final String stableKey;
  final int categoryId;
  final String domainKey;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;

  const PublishedCurriculumSkill({
    required this.stableKey,
    required this.categoryId,
    required this.domainKey,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
  });

  factory PublishedCurriculumSkill.fromJson(Map<String, dynamic> json) {
    String value(String key) {
      final lower = key[0].toLowerCase() + key.substring(1);
      return (json[key] ?? json[lower] ?? '').toString().trim();
    }

    final rawId = json['CategoryId'] ?? json['categoryId'];
    final categoryId = rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0;
    final stableKey = value('StableKey');
    final nameAr = value('NameAr');
    final nameEn = value('NameEn');
    if (categoryId <= 0 || stableKey.isEmpty || nameAr.isEmpty || nameEn.isEmpty) {
      throw const FormatException('Invalid published curriculum skill');
    }

    return PublishedCurriculumSkill(
      stableKey: stableKey,
      categoryId: categoryId,
      domainKey: value('DomainKey'),
      nameAr: nameAr,
      nameEn: nameEn,
      descriptionAr: value('DescriptionAr'),
      descriptionEn: value('DescriptionEn'),
    );
  }

  String localizedName(String locale) => locale == 'ar' ? nameAr : nameEn;
  String localizedDescription(String locale) =>
      locale == 'ar' ? descriptionAr : descriptionEn;
}
