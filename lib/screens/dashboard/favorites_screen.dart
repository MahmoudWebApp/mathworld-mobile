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

/// Displays localized favorite problems with consistent spacing.
class FavoritesScreen extends ConsumerStatefulWidget {
  final bool embedded;
  final VoidCallback? onOpenStages;

  const FavoritesScreen({
    super.key,
    this.embedded = false,
    this.onOpenStages,
  });

  @override
  ConsumerState<FavoritesScreen> createState()=>_FavoritesScreenState();
}
class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int _page=1;
  @override
  Widget build(BuildContext context) {
    final embedded=widget.embedded;
    final onOpenStages=widget.onOpenStages;
    final favoritesState = ref.watch(favoritesProvider(_page));

    final body = MathBackground(
      child: SafeArea(
        bottom: false,
        child: favoritesState.when(
            skipLoadingOnRefresh:false,skipLoadingOnReload:false,
          loading: () => AppContentSkeleton(count:5,title:embedded?'favorites'.tr():null),
          error: (error, __) => AppErrorView(
            message: localizedErrorMessage(error),
            onRetry: () => ref.invalidate(favoritesProvider),
          ),
          data: (result) {
            final items=result.problems;
            if(items.isEmpty&&_page>1) {
              return Center(child:TextButton(onPressed:()=>setState(()=>_page=1),child:Text(context.locale.languageCode=='ar'?'العودة لأول صفحة':'Back to first page')));
            }
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  132,
                ),
                children: [
                  if (embedded) ...[
                    Text(
                      'favorites'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  AppEmptyView(
                    icon: Icons.favorite_border,
                    title: 'no_favorites_yet'.tr(),
                    action: FilledButton.icon(
                      onPressed: () {
                        if (onOpenStages != null) {
                          onOpenStages();
                        } else {
                          Navigator.pushNamed(context, AppRoutes.home,
                              arguments: {'initialTab': 1});
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: Text('browse_all'.tr()),
                    ),
                  ),
                ],
              );
            }

            final headerOffset = embedded ? 2 : 1;

            return RefreshIndicator(
              onRefresh: () => ref.refresh(favoritesProvider(_page).future),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  embedded ? 132 : AppSpacing.xxl,
                ),
                itemCount: items.length + headerOffset + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) {
                  if (embedded && index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'favorites'.tr(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    );
                  }

                  if (index == (embedded ? 1 : 0)) {
                    return CompactProblemCount(
                      count: result.total,
                      label: context.locale.languageCode == 'ar'
                          ? 'إجمالي المفضلة' : 'Favorites',
                      icon: Icons.favorite_rounded,
                      accent: AppColors.error,
                    );
                  }
                  if(index==items.length+headerOffset)return MathWorldPagination(page:result.page,pageCount:result.totalPages,arabic:context.locale.languageCode=='ar',onChanged:(p)=>setState(()=>_page=p));
                  final problem = items[index - headerOffset];
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
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text('favorites'.tr())),
      body: body,
    );
  }
}
