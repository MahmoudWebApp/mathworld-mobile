import 'package:easy_localization/easy_localization.dart';
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

  const ProblemCard({
    super.key,
    required this.problem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.darkText : AppColors.lightText;

    return GlassCard(
      onTap: onTap,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.functions_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: RichMathText(
                  text: problem.title,
                  inline: true,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                children: [
                  if (problem.isSolved)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                  if (problem.isFavorite)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: AppColors.error,
                        size: 19,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Icon(
                      LayoutUtils.forwardChevron(context),
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetaPill(
                icon: Icons.category_outlined,
                label: problem.categoryName,
                color: Theme.of(context).colorScheme.primary,
              ),
              _MetaPill(
                icon: Icons.star_rounded,
                label: 'points_value'.tr(
                  namedArgs: {'count': '${problem.points}'},
                ),
                color: AppColors.warning,
              ),
              _MetaPill(
                icon: Icons.visibility_outlined,
                label: 'views_value'.tr(
                  namedArgs: {'count': '${problem.viewsCount}'},
                ),
                color: AppColors.cyan,
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

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
