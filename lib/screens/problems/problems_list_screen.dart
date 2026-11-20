import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/error_message.dart';
import '../../providers/problems_provider.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/app_states.dart';
import '../../widgets/math_background.dart';
import '../../widgets/problem_card.dart';

/// Displays localized problems with search and pagination.
class ProblemsListScreen extends ConsumerStatefulWidget {
  const ProblemsListScreen({super.key});

  @override
  ConsumerState<ProblemsListScreen> createState() => _ProblemsListScreenState();
}

class _ProblemsListScreenState extends ConsumerState<ProblemsListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _page = 1;
  int? _categoryId;
  int? _stageId;
  String? _query;
  String? _title;
  bool _routeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final categoryValue = arguments is Map ? arguments['categoryId'] : null;
    final stageValue = arguments is Map ? arguments['stageId'] : null;
    final titleValue = arguments is Map
        ? arguments['title'] ?? arguments['categoryName']
        : null;
    final nextCategoryId = categoryValue is int && categoryValue > 0
        ? categoryValue : null;
    final nextStageId = stageValue is int && stageValue > 0
        ? stageValue : null;
    final nextTitle = titleValue is String && titleValue.trim().isNotEmpty
        ? titleValue : null;

    // Reused routes must never show a previous stage's or category's results.
    // Do not reset the learner's search just because locale/theme rebuilt.
    if (!_routeInitialized || _categoryId != nextCategoryId ||
        _stageId != nextStageId || _title != nextTitle) {
      _routeInitialized = true;
      _debounce?.cancel();
      _categoryId = nextCategoryId;
      _stageId = nextStageId;
      _title = nextTitle;
      _page = 1;
      _query = null;
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _query = value.trim().isEmpty ? null : value.trim();
        _page = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final parameters = ProblemSearchParams(
      query: _query,
      categoryId: _categoryId,
      stageId: _stageId,
      page: _page,
    );
    final problemsState = ref.watch(problemsProvider(parameters));

    return Scaffold(
      appBar: AppBar(title: Text(
        _title ?? 'problems'.tr(),
        style: _stageId == null ? null : TextStyle(
          color: AppColors.stageForOrder(_stageId!),
          fontWeight: FontWeight.w800,
        ),
      )),
      body: MathBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: SearchBar(
                controller: _searchController,
                hintText: 'search_placeholder'.tr(),
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: context.locale.languageCode == 'ar'
                          ? 'مسح البحث' : 'Clear search',
                      onPressed: () {
                        _debounce?.cancel();
                        _searchController.clear();
                        setState(() {
                          _query = null;
                          _page = 1;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
                onChanged: (value) {
                  _handleSearch(value);
                  setState(() {});
                },
                onSubmitted: (value) {
                  _debounce?.cancel();
                  setState(() {
                    _query = value.trim().isEmpty ? null : value.trim();
                    _page = 1;
                  });
                },
              ),
            ),
            Expanded(
              child: problemsState.when(
                loading: () => const _ProblemsSkeleton(),
                error: (error, __) {
                  if (error is AppException &&
                      error.type == AppExceptionType.forbidden &&
                      _categoryId != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AppEmptyView(
                          icon: Icons.lock_outline_rounded,
                          title: 'category_locked_explanation_title'.tr(),
                          subtitle: 'category_locked_explanation_body'.tr(),
                          action: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.maybePop(context);
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text('category_locked_continue_free'.tr()),
                          ),
                        ),
                      ),
                    );
                  }
                  return AppErrorView(
                    message: localizedErrorMessage(error),
                    onRetry: () => ref.invalidate(
                      problemsProvider(parameters),
                    ),
                  );
                },
                data: (result) {
                  if (result.problems.isEmpty) {
                    // An empty page must still support pull-to-refresh and
                    // an accessible clear-search action on small devices.
                    return RefreshIndicator(
                      onRefresh: () => ref.refresh(
                        problemsProvider(parameters).future,
                      ),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: AppEmptyView(
                              icon: Icons.search_off_rounded,
                              title: _page > 1
                                  ? (context.locale.languageCode == 'ar'
                                      ? 'لا توجد مسائل في هذه الصفحة'
                                      : 'No problems on this page')
                                  : 'no_results'.tr(),
                              subtitle: _page > 1
                                  ? (context.locale.languageCode == 'ar'
                                      ? 'يمكن أن يكون المحتوى تغيّر أثناء التصفح.'
                                      : 'The question list may have changed.')
                                  : _query == null
                                      ? null
                                      : context.locale.languageCode == 'ar'
                                          ? 'جرّب كلمة بحث أخرى أو امسح البحث لعرض المسائل.'
                                          : 'Try another term or clear search to browse problems.',
                              action: _page > 1
                                  ? FilledButton.icon(
                                      onPressed: () => setState(() => _page = 1),
                                      icon: const Icon(Icons.first_page_rounded),
                                      label: Text(context.locale.languageCode == 'ar'
                                          ? 'العودة لأول صفحة' : 'Back to first page'),
                                    )
                                  : _query == null
                                      ? null
                                      : OutlinedButton.icon(
                                      onPressed: () {
                                        _debounce?.cancel();
                                        _searchController.clear();
                                        setState(() {
                                          _query = null;
                                          _page = 1;
                                        });
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                      label: Text(context.locale.languageCode == 'ar'
                                          ? 'مسح البحث'
                                          : 'Clear search'),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(
                      problemsProvider(parameters).future,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      itemCount: result.problems.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) {
                        if (index == result.problems.length) {
                          return _PaginationControls(
                            page: result.page,
                            totalPages: result.totalPages,
                            onPrevious: result.page > 1
                                ? () => setState(() => _page--)
                                : null,
                            onNext: result.hasMorePages
                                ? () => setState(() => _page++)
                                : null,
                          );
                        }

                        final problem = result.problems[index];
                        return ProblemCard(
                          problem: problem,
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.problemDetails,
                              arguments: problem.id,
                            );
                            // The solved tag and server-wide unsolved-first order
                            // must refresh when returning from an answer.
                            if (context.mounted) {
                              ref.invalidate(problemsProvider(parameters));
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationControls({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.xl,
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onPrevious,
            tooltip: 'previous'.tr(),
            icon: LayoutUtils.previousPageIcon(context),
          ),
          Expanded(
            child: Text(
              'page_of'.tr(
                namedArgs: {
                  'page': '$page',
                  'total': '$totalPages',
                },
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton.filledTonal(
            onPressed: onNext,
            tooltip: 'next'.tr(),
            icon: LayoutUtils.nextPageIcon(context),
          ),
        ],
      ),
    );
  }
}

class _ProblemsSkeleton extends StatelessWidget {
  const _ProblemsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (_, __) => Container(
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
