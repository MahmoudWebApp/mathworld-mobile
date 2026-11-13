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
import '../../widgets/premium_button.dart';
import '../../utils/layout_utils.dart';

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
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).chooseLearningStage(id);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
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
            data: (items) => ListView(
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
                const SizedBox(height: AppSpacing.xl),
                ...items.map((stage) {
                  final selected = effective == stage.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        leading: Icon(
                          selected ? Icons.check_circle : Icons.school_outlined,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          stage.getName(language),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        selected: selected,
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
                  label: 'save_learning_stage'.tr(),
                  leadingIcon: LayoutUtils.forwardArrow(context),
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
