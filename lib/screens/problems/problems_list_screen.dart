import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      _categoryId ??= arguments['categoryId'] as int?;
      _stageId ??= arguments['stageId'] as int?;
      _title ??= (arguments['title'] ?? arguments['categoryName']) as String?;
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
      appBar: AppBar(title: Text(_title ?? 'problems'.tr())),
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
                      onPressed: () {
                        _searchController.clear();
                        _handleSearch('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
                onChanged: (value) {
                  _handleSearch(value);
                  setState(() {});
                },
              ),
            ),
            Expanded(
              child: problemsState.when(
                loading: () => const _ProblemsSkeleton(),
                error: (error, __) => AppErrorView(
                  message: localizedErrorMessage(error),
                  onRetry: () => ref.invalidate(
                    problemsProvider(parameters),
                  ),
                ),
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
                              title: 'no_results'.tr(),
                              subtitle: _query == null
                                  ? null
                                  : context.locale.languageCode == 'ar'
                                      ? 'جرّب كلمة بحث أخرى أو امسح البحث لعرض المسائل.'
                                      : 'Try another term or clear search to browse problems.',
                              action: _query == null
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
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.problemDetails,
                            arguments: problem.id,
                          ),
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
