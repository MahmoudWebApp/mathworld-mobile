import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The backend remains authoritative for problem access.
class StageCategoryAccess {
  final int stageId;
  final List<StageCategoryItem> categories;
  final List<int> freeCategoryIds;

  const StageCategoryAccess({
    required this.stageId,
    required this.categories,
    required this.freeCategoryIds,
  });

  factory StageCategoryAccess.fromJson(Map<String, dynamic> json) {
    return StageCategoryAccess(
      stageId: ((json['StageId'] ?? json['stageId']) as num).toInt(),
      categories: ((json['Categories'] ?? json['categories']) as List<dynamic>)
          .map((item) => StageCategoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      freeCategoryIds: ((json['FreeCategoryIds'] ?? json['freeCategoryIds']) as List<dynamic>)
          .map((id) => (id as num).toInt())
          .toList(),
    );
  }
}

class StageCategoryItem {
  final int id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String icon;
  final int order;
  final int? problemsCount;
  final bool isFree;

  const StageCategoryItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr = '',
    this.descriptionEn = '',
    required this.icon,
    required this.order,
    required this.problemsCount,
    required this.isFree,
  });

  factory StageCategoryItem.fromJson(Map<String, dynamic> json) {
    return StageCategoryItem(
      id: ((json['Id'] ?? json['id']) as num).toInt(),
      nameAr: (json['NameAr'] ?? json['nameAr']) as String? ?? '',
      nameEn: (json['NameEn'] ?? json['nameEn']) as String? ?? '',
      icon: (json['Icon'] ?? json['icon']) as String? ?? '📐',
      descriptionAr: (json['DescriptionAr'] ?? json['descriptionAr']) as String? ?? '',
      descriptionEn: (json['DescriptionEn'] ?? json['descriptionEn']) as String? ?? '',
      order: ((json['Order'] ?? json['order']) as num?)?.toInt() ?? 0,
      problemsCount: ((json['ProblemsCount'] ?? json['problemsCount']) as num?)?.toInt(),
      isFree: (json['IsFree'] ?? json['isFree']) == true,
    );
  }

  bool canOpen({required bool isPremium}) => isPremium || isFree;
}

class StageCategoryAccessRepository {
  final Dio dio;
  const StageCategoryAccessRepository(this.dio);

  Future<StageCategoryAccess> load(int stageId) async {
    if (stageId <= 0) throw ArgumentError.value(stageId, 'stageId');
    final response = await dio.get<Map<String, dynamic>>(
      '/api/stages/$stageId/free-categories',
    );
    final data = response.data;
    if (data == null) throw const FormatException('Missing stage catalog');
    final catalog = StageCategoryAccess.fromJson(data);
    if (catalog.stageId != stageId) {
      throw const FormatException('Unexpected stage catalog');
    }
    return catalog;
  }
}

/// Reusable category chooser. The host app supplies its configured Dio instance,
/// subscription entitlement and navigation/upgrade callbacks.
class StageCategoryAccessGrid extends StatelessWidget {
  final StageCategoryAccess catalog;
  final bool isPremium;
  final bool isArabic;
  final ValueChanged<int> onOpenCategory;
  final VoidCallback? onUpgrade;

  const StageCategoryAccessGrid({
    super.key,
    required this.catalog,
    required this.isPremium,
    required this.isArabic,
    required this.onOpenCategory,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isPremium
              ? (isArabic ? 'جميع الفئات متاحة دون حد يومي' : 'All categories, unlimited daily practice')
              : (isArabic ? 'فئتان مجانيتان لكل مرحلة دون حد يومي' : 'Two free categories per stage, unlimited daily practice')),
          const SizedBox(height: 12),
          ...catalog.categories.map((category) {
            final unlocked = category.canOpen(isPremium: isPremium);
            return Card(
              child: ListTile(
                leading: category.icon.startsWith('https://') && category.icon.toLowerCase().endsWith('.svg')
                    ? SvgPicture.network(category.icon, width: 32, height: 32,
                        errorBuilder: (_, __, ___) => const Icon(Icons.calculate_outlined))
                    : category.icon.startsWith('http')
                        ? Image.network(category.icon, width: 32, height: 32,
                            errorBuilder: (_, __, ___) => const Icon(Icons.calculate_outlined))
                        : Text(category.icon.runes.length <= 4 ? category.icon : '∑'),
                title: Text(isArabic ? category.nameAr : category.nameEn),
                subtitle: Text(unlocked
                    ? (isArabic ? 'متاحة' : 'Unlocked')
                    : (isArabic ? 'مقفلة' : 'Locked')),
                trailing: TextButton(
                  onPressed: unlocked
                      ? () => onOpenCategory(category.id)
                      : onUpgrade,
                  child: Text(unlocked
                      ? (isArabic ? 'ابدأ الحل' : 'Start solving')
                      : (isArabic ? 'افتح مع Premium' : 'Unlock with Premium')),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
