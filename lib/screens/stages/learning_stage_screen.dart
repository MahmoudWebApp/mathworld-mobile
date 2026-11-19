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
  const LearningStageScreen({super.key, this.onCreateAccount});

  /// Only initial registration provides this; stage changes use the account API.
  final Future<void> Function(int stageId)? onCreateAccount;

  @override
  ConsumerState<LearningStageScreen> createState() =>
      _LearningStageScreenState();
}

class _LearningStageScreenState extends ConsumerState<LearningStageScreen> {
  int? _selectedStageId;
  bool _saving = false;

  Future<void> _save(int id) async {
    if (_saving) return;
    if (widget.onCreateAccount != null) {
      setState(() => _saving = true);
      try {
        await widget.onCreateAccount!(id);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.home, (_) => false,
          arguments: const {'initialTab': 1},
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizedErrorMessage(error))),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }
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
      appBar: AppBar(title: Text(widget.onCreateAccount != null
          ? (context.locale.languageCode == 'ar' ? 'اختيار المرحلة' : 'Choose a stage')
          : 'learning_stage'.tr())),
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
                  widget.onCreateAccount == null ? 'choose_learning_stage_title'.tr()
                    : (language == 'ar' ? 'اختار مرحلتك التعليمية' : 'Choose your learning stage'),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.onCreateAccount == null ? 'choose_learning_stage_desc'.tr()
                    : (language == 'ar'
                        ? 'اختار المرحلة اللي بتناسبك حتى نعرض فئاتها ومسائلها بعد إنشاء حسابك.'
                        : 'Choose your stage to see its topics and problems once your account is created.'),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final count = constraints.maxWidth >= 760 ? 4
                      : constraints.maxWidth >= 540 ? 3 : 2;
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisExtent: (165.0 + (scale - 1).clamp(0.0, 1.0) * 45).toDouble(),
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final stage = items[index];
                        final selected = effective == stage.id;
                        final accent = AppColors.stageForOrder(stage.order);
                        return GlassCard(
                          onTap: _saving ? null : () => setState(() => _selectedStageId = stage.id),
                          border: BorderSide(color: accent.withValues(alpha: selected ? .8 : .22),
                            width: selected ? 2 : 1),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                StageMathGlyph(stageOrder: stage.order, color: accent, size: 43),
                                const Spacer(),
                                if (selected) Icon(Icons.check_circle_rounded,
                                  color: accent, size: 21),
                              ]),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                stage.getName(language),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: accent, fontWeight: FontWeight.w900),
                              ),
                              const Spacer(),
                              if (user?.currentStageId == stage.id)
                                Text(language == 'ar' ? 'المرحلة الحالية' : 'Current stage',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                PremiumButton(
                  label: widget.onCreateAccount != null
                      ? (language == 'ar' ? 'إكمال إنشاء الحساب' : 'Finish registration')
                      : effective != null && effective == user?.currentStageId
                      ? (language == 'ar' ? 'استكشف الفئات' : 'Explore topics')
                      : (language == 'ar' ? 'حفظ المرحلة والمتابعة' : 'Save stage and continue'),
                  trailingIcon: Icons.arrow_forward_rounded,
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
