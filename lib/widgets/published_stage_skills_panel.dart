import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/design_tokens.dart';
import '../models/category.dart';
import '../providers/published_curriculum_skills_provider.dart';

/// Optional learning-objective disclosure, matched to the live stage catalogue.
/// It never exposes answers or circumvents Free/Premium question access.
class PublishedStageSkillsPanel extends ConsumerWidget {
  final int stageId;
  final List<Category> categories;

  const PublishedStageSkillsPanel({
    super.key,
    required this.stageId,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publishedCurriculumSkillsProvider(stageId));
    final skills = state.valueOrNull;
    // The optional metadata may not exist on older backend releases.
    // Its absence must never hide or block real categories.
    if (skills == null || skills.isEmpty) return const SizedBox.shrink();

    final groups = <Category, List<String>>{};
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    for (final category in categories) {
      final names = skills
          .where((skill) => skill.categoryId == category.id)
          .map((skill) => skill.localizedName(ar ? 'ar' : 'en'))
          .toList(growable: false);
      if (names.isNotEmpty) groups[category] = names;
    }
    if (groups.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
          ),
          leading: Icon(Icons.account_tree_outlined, color: colors.primary),
          title: Text(
            ar ? 'المهارات الرياضية المنشورة' : 'Published mathematical skills',
            style: textStyle.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            ar
                ? 'استكشف مهارات الفئات المنشورة حسب موضوعها.'
                : 'Explore learning objectives grouped by topic.',
            style: textStyle.bodySmall,
          ),
          children: [
            for (final entry in groups.entries) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  entry.key.getName(ar ? 'ar' : 'en'),
                  style: textStyle.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final name in entry.value)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(name, style: textStyle.bodySmall),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              ar
                  ? 'هذه أهداف تعليمية وليست نسب إتقان أو اعتماداً رسمياً. يُحسب تقدمك من محاولاتك الفعلية.'
                  : 'These are learning objectives, not mastery percentages or official accreditation. Progress comes from real attempts.',
              style: textStyle.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
