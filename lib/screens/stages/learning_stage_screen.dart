import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stages_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/stage_math_glyph.dart';
import '../../widgets/premium_button.dart';

/// First-login stage onboarding and later stage switching.
/// All progress stays assigned to the original question stage in the API.
class LearningStageScreen extends ConsumerStatefulWidget {
  const LearningStageScreen({super.key});

  @override
  ConsumerState<LearningStageScreen> createState() =>
      _LearningStageScreenState();
}

class _LearningStageScreenState extends ConsumerState<LearningStageScreen> {
  int? _selectedStageId;
  bool _saving = false;

  Future<void> _save(int id) async {
    if (_saving) return;
    // Keeping the already-selected stage is navigation, not a new server
    // mutation. Avoid a needless PUT or invalidating student progress caches.
    if (ref.read(authProvider).user?.currentStageId == id) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.home, (_) => false,
        arguments: const {'initialTab': 1},
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).chooseLearningStage(id);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
        arguments: const {'initialTab': 1},
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = ref.watch(stagesProvider);
    final user = ref.watch(authProvider).user;
    final effective = _selectedStageId ?? user?.currentStageId;
    final language = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text('learning_stage'.tr())),
      body: MathBackground(
        showSymbols: true,
        child: SafeArea(
          child: stages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(localizedErrorMessage(error)),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => ref.invalidate(stagesProvider),
                    child: Text('retry'.tr()),
                  ),
                ],
              ),
            ),
            data: (items) => items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined, size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            language == 'ar'
                                ? 'لا توجد مراحل تعليمية متاحة حالياً'
                                : 'No learning stages are available yet',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: () => ref.invalidate(stagesProvider),
                            icon: const Icon(Icons.refresh),
                            label: Text('retry'.tr()),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  'choose_learning_stage_title'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'choose_learning_stage_desc'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  language == 'ar'
                      ? 'يمكنك تغيير المرحلة لاحقاً دون فقدان نقاطك أو حلولك القديمة.'
                      : 'You can switch stages later without losing earlier points or solutions.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ...items.map((stage) {
                  final selected = effective == stage.id;
                  const tones = [
                    AppColors.stageCyan, AppColors.stageOrange,
                    AppColors.stageGreen, AppColors.stageViolet,
                  ];
                  final accent = tones[(stage.order <= 0 ? 0 : stage.order - 1) % tones.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        leading: Container(
                          width: 48, height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: accent.withValues(alpha: .12),
                            border: Border.all(color: accent.withValues(alpha: .28)),
                          ),
                          child: selected
                              ? Icon(Icons.check_circle_rounded, color: accent, size: 28)
                              : StageMathGlyph(stageOrder: stage.order, color: accent, size: 36),
                        ),
                        title: Text(
                          stage.getName(language),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        selected: selected,
                        subtitle: user?.currentStageId == stage.id
                            ? Text(language == 'ar'
                                ? 'مرحلتك الحالية'
                                : 'Your current stage')
                            : null,
                        onTap: _saving
                            ? null
                            : () => setState(() {
                                  _selectedStageId = stage.id;
                                }),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.lg),
                PremiumButton(
                  label: effective != null && effective == user?.currentStageId
                      ? (language == 'ar' ? 'عرض فئاتي المفتوحة' : 'See my unlocked topics')
                      : (language == 'ar' ? 'حفظ المرحلة وعرض الفئات' : 'Save stage and show topics'),
                  leadingIcon: Icons.arrow_forward_rounded,
                  onPressed: effective == null || _saving
                      ? null
                      : () => _save(effective),
                  isLoading: _saving,
                  expand: true,
                ),
                if (effective == null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'select_stage_to_continue'.tr(),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
