import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/user_lists_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/math_background.dart';
import '../../widgets/problem_card.dart';

/// Displays localized solved problems with consistent spacing.
class SolvedScreen extends ConsumerWidget {
  const SolvedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solvedState = ref.watch(solvedProvider);

    return Scaffold(
      appBar: AppBar(title: Text('solved_problems'.tr())),
      body: MathBackground(
        child: SafeArea(
          child: solvedState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, __) => AppErrorView(
              message: localizedErrorMessage(error),
              onRetry: () => ref.invalidate(solvedProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    AppEmptyView(
                      icon: Icons.check_circle_outline,
                      title: 'no_solved_yet'.tr(),
                      action: FilledButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.problems);
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text('start_solving'.tr()),
                      ),
                    ),
                  ],
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.refresh(solvedProvider.future),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    final problem = items[index];
                    return ProblemCard(
                      problem: problem,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.problemDetails,
                          arguments: problem.id,
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
