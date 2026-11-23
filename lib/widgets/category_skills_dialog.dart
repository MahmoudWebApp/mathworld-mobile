import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/design_tokens.dart';
import '../models/category.dart';
import '../providers/published_curriculum_skills_provider.dart';

/// Published curriculum metadata shared with MathWorld web. No solutions or
/// Premium-only question details are returned by this dialog.
Future<void> showCategorySkillsDialog(
  BuildContext context, {
  required Category category,
  required int stageId,
  required int stageOrder,
}) async {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  final accent = AppColors.stageForOrder(stageOrder);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Consumer(
      builder: (context, ref, _) {
        final skills = ref.watch(publishedCurriculumSkillsProvider(stageId));
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.fact_check_outlined, color: accent),
              const SizedBox(width: 8),
              Expanded(child: Text(ar ? 'المهارات التعليمية' : 'Learning skills')),
            ],
          ),
          content: SizedBox(
            width: 470,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.getName(ar ? 'ar' : 'en'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
                const SizedBox(height: 12),
                // AlertDialog content receives intrinsic/unbounded height.
                // Never place Flexible here; constrain the scrolling list.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: skills.when(
                    loading: () => const Center(
                      child: Padding(padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ar ? 'تعذّر تحميل المهارات من الخادم.' :
                          'Could not load learning skills.'),
                        TextButton.icon(
                          onPressed: () => ref.invalidate(
                            publishedCurriculumSkillsProvider(stageId)),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ],
                    ),
                    data: (all) {
                      final own = all.where((skill) =>
                        skill.categoryId == category.id).toList(growable: false);
                      if (own.isEmpty) {
                        return Text(ar
                          ? 'مهارات هذه الفئة قيد المراجعة التعليمية، وما منشورة بعد.'
                          : 'Learning objectives for this topic are under editorial review.');
                      }
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0; index < own.length; index++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                  tileColor: Theme.of(context)
                                    .colorScheme.surfaceContainerLow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: accent.withValues(alpha: .12),
                                    child: Text('${index + 1}', style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.bold,
                                      color: accent)),
                                  ),
                                  title: Text(own[index].localizedName(ar ? 'ar' : 'en'),
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                  // Existing published records often copy
                                  // the title into Description; don't show it twice.
                                  subtitle: own[index].localizedDescription(
                                        ar ? 'ar' : 'en').trim().isEmpty ||
                                      own[index].localizedDescription(
                                        ar ? 'ar' : 'en').trim() ==
                                      own[index].localizedName(
                                        ar ? 'ar' : 'en').trim()
                                    ? null
                                    : Text(own[index].localizedDescription(
                                        ar ? 'ar' : 'en')),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(ar
                  ? 'هذه أهداف تعلّم وليست نسب إتقان أو اعتماداً رسمياً.'
                  : 'These are objectives, not mastery percentages or accreditation.',
                  style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(ar ? 'إغلاق' : 'Close'),
            ),
          ],
        );
      },
    ),
  );
}
