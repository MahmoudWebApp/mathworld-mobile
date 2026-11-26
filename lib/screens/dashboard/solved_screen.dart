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
import '../../widgets/compact_problem_count.dart';
import '../../widgets/mathworld_pagination.dart';

/// Displays localized solved problems with consistent spacing.
class SolvedScreen extends ConsumerStatefulWidget {
  const SolvedScreen({super.key});

  @override
  ConsumerState<SolvedScreen> createState()=>_SolvedScreenState();
}
class _SolvedScreenState extends ConsumerState<SolvedScreen> {
  int _page=1;
  @override
  Widget build(BuildContext context) {
    final solvedState = ref.watch(solvedProvider(_page));

    return Scaffold(
      appBar: AppBar(title: Text('solved_problems'.tr())),
      body: MathBackground(
        child: SafeArea(
          child: solvedState.when(
            skipLoadingOnRefresh:false,skipLoadingOnReload:false,
            loading: () => const AppContentSkeleton(),
            error: (error, __) => AppErrorView(
              message: localizedErrorMessage(error),
              onRetry: () => ref.invalidate(solvedProvider),
            ),
            data: (result) {
            final items=result.problems;
            if(items.isEmpty&&_page>1) {
              return Center(child:TextButton(onPressed:()=>setState(()=>_page=1),child:Text(context.locale.languageCode=='ar'?'العودة لأول صفحة':'Back to first page')));
            }
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
                          Navigator.pushNamed(context, AppRoutes.home,
                            arguments: {'initialTab': 1});
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text('start_solving'.tr()),
                      ),
                    ),
                  ],
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.refresh(solvedProvider(_page).future),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: items.length + 2,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return CompactProblemCount(
                        count: result.total,
                        label: Localizations.localeOf(context).languageCode == 'ar'
                            ? 'إجمالي المحلولة' : 'Solved questions',
                        icon: Icons.check_circle_outline_rounded,
                        accent: AppColors.success,
                      );
                    }
                    if(index==items.length+1)return MathWorldPagination(page:result.page,pageCount:result.totalPages,arabic:context.locale.languageCode=='ar',onChanged:(p)=>setState(()=>_page=p));
                    final problem = items[index - 1];
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
