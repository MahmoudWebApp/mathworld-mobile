import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../widgets/mathworld_pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/error_message.dart';
import '../../providers/problems_provider.dart';
import '../../providers/learning_tracks_provider.dart';
import '../../providers/auth_provider.dart';
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
  bool _hideSolved = false;
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
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
    final learnerStageId = ref.watch(authProvider.select((state) =>
      state.user?.role == 'Student' ? state.user?.currentStageId : null));
    final effectiveStageId = learnerStageId ?? _stageId;
    final parameters = ProblemSearchParams(
      query: _query,
      categoryId: _categoryId,
      stageId: effectiveStageId,
      hideSolved: _hideSolved,
      page: _page,
    );
    final problemsState = ref.watch(problemsProvider(parameters));
    final searching = _searchController.text.trim() != (_query ?? '');

    return Scaffold(
      appBar: AppBar(title: Text(
        _title ?? 'problems'.tr(),
        style: _stageId == null ? null : TextStyle(
          color: AppColors.stageForOrder(_stageId!),
          fontWeight: FontWeight.w800,
        ),
      )),
      body: MathBackground(
        child: SafeArea(top:false,child: Column(
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
                leading: searching||problemsState.isLoading&&_query!=null?const AppInlineLoader(size:18):const Icon(Icons.search_rounded),
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
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg, end: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilterChip(
                  selected: _hideSolved,
                  avatar: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(context.locale.languageCode == 'ar'
                      ? 'إخفاء المحلولة' : 'Hide solved'),
                  onSelected: (selected) => setState(() {
                    _hideSolved = selected;
                    _page = 1;
                  }),
                ),
              ),
            ),
            Expanded(
              child: problemsState.when(
                skipLoadingOnRefresh:true,skipLoadingOnReload:false,
                loading: () => const AppContentSkeleton(count:5),
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
                            icon: LayoutUtils.backIcon(context),
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
                                  : _hideSolved && _query == null
                                      ? (context.locale.languageCode == 'ar'
                                          ? 'لا توجد مسائل غير محلولة'
                                          : 'No unsolved problems')
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
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == result.problems.length) {
                          return Padding(padding:const EdgeInsets.symmetric(vertical:AppSpacing.lg),child:MathWorldPagination(
                            page:result.page,pageCount:result.totalPages,arabic:context.locale.languageCode=='ar',
                            onChanged:(page)=>setState(()=>_page=page),
                          ));
                        }

                        final problem = result.problems[index];
                        return ProblemCard(
                          showCategory: _categoryId == null,
                          problem: problem,
                          onTap: () async {
                            final items=result.problems;
                            var current=index;
                            final owner=ref.read(authProvider).user?.id;
                            if(owner==null)return;
                            // For active grades, use the server continuation even
                            // when this question was opened from a mixed search.
                            int trackId=0;
                            try {
                              final selection=await ref.read(trackSelectionProvider.future);
                              if(trackNumber(selection['StageId'])==problem.stageId)trackId=trackNumber(selection['TrackId']);
                            }catch(_){}
                            if(!mounted||ref.read(authProvider).user?.id!=owner)return;
                            if(trackId>0){
                              var currentId=problem.id;
                              var retry=false;
                              final visited=<int>{};
                              while(mounted&&ref.read(authProvider).user?.id==owner&&visited.add(currentId)){
                                final submitted=await Navigator.pushNamed(this.context,AppRoutes.problemDetails,arguments:{
                                  'problemId':currentId,'trackId':trackId,'categoryId':problem.categoryId,'retry':retry,
                                });
                                if(!mounted||ref.read(authProvider).user?.id!=owner||submitted is! NextTrackCandidate)break;
                                currentId=submitted.id;
                                retry=submitted.retry;
                              }
                              if(mounted&&ref.read(authProvider).user?.id==owner)ref.invalidate(problemsProvider(parameters));
                              return;
                            }
                            while(mounted&&ref.read(authProvider).user?.id==owner){
                              final next=items.indexWhere((item)=>item.categoryId==items[current].categoryId&&item.stageId==items[current].stageId&&!item.isSolved&&!item.hasAttempted,current+1);
                              final submitted=await Navigator.pushNamed(
                                this.context,AppRoutes.problemDetails,arguments:{
                                  'problemId':items[current].id,
                                  if(next>=0)'nextProblemId':items[next].id,
                                },
                              );
                              if(!mounted||ref.read(authProvider).user?.id!=owner)break;
                              if(submitted==true||submitted=='nextProblem')ref.invalidate(problemsProvider(parameters));
                              if(submitted!='nextProblem'||next<0)break;
                              current=next;
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
        )),
      ),
    );
  }
}

