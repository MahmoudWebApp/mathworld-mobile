import 'package:flutter/material.dart';

import '../config/design_tokens.dart';
import '../models/problem.dart';
import '../utils/layout_utils.dart';
import 'glass_card.dart';
import 'rich_math_text.dart';

/// Displays a spacious localized problem preview with rendered math content.
class ProblemCard extends StatelessWidget {
  final ProblemPreview problem;
  final VoidCallback onTap;
  final bool showCategory;

  const ProblemCard({
    super.key,
    required this.problem,
    required this.onTap,
    this.showCategory = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.darkText : AppColors.lightText;
    final stageAccent = AppColors.stageForIdentity(problem.stageId, problem.stageName);

    return GlassCard(
      onTap: onTap,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: stageAccent.withValues(alpha:.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.functions_rounded,
                  color: stageAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: RichMathText(
                  text: problem.title,
                  inline: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Points star and View action remain at the top corner in
              // RTL and LTR, including small phones (not below the badges).
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                        size: 17, color: AppColors.pointsGold(context)),
                      const SizedBox(width: 3),
                      Text('${problem.points}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.pointsGold(context), fontWeight: FontWeight.w800)),
                    ],
                  ),
                  if (problem.isSolved)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 18),
                    ),
                  if (problem.isFavorite)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.favorite_rounded,
                        color: AppColors.error, size: 18),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Localizations.localeOf(context).languageCode == 'ar' ? 'عرض' : 'View',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: stageAccent, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 3),
                      LayoutUtils.forwardIcon(context,
                        size: 17, color: stageAccent),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (problem.progressKnown || showCategory) const SizedBox(height: AppSpacing.sm),
          if (problem.progressKnown || showCategory) Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (problem.progressKnown) _MetaPill(
                icon: problem.isSolved
                    ? Icons.check_circle_outline_rounded
                    : problem.hasAttempted
                        ? Icons.error_outline_rounded
                        : Icons.fiber_new_outlined,
                label: problem.isSolved
                    ? (Localizations.localeOf(context).languageCode == 'ar' ? 'محلولة' : 'Solved')
                    : problem.hasAttempted
                        ? (Localizations.localeOf(context).languageCode == 'ar' ? 'تحتاج مراجعة' : 'Needs review')
                        : (Localizations.localeOf(context).languageCode == 'ar' ? 'جديدة' : 'New'),
                color: problem.isSolved ? AppColors.success
                    : problem.hasAttempted ? AppColors.warning
                    : AppColors.success,
                tintLabel: !problem.isSolved && !problem.hasAttempted,
              ),
              if (showCategory) _MetaPill(
                icon: Icons.category_outlined,
                label: problem.categoryName,
                color: stageAccent,
              ),

            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool tintLabel;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
    this.tintLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tintLabel ? (Theme.of(context).brightness == Brightness.dark && color == AppColors.success ? const Color(0xFF80D8B7) : const Color(0xFF176B50)) : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
