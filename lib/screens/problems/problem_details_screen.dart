import 'dart:ui' as ui;
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../widgets/mathworld_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../utils/layout_utils.dart';
import '../../core/utils/error_message.dart';
import '../../models/problem.dart';
import '../../providers/auth_provider.dart';
import '../../providers/problem_details_provider.dart';
import '../../providers/problem_prefetch_provider.dart';
import '../../providers/learning_tracks_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/rich_math_text.dart';
import '../../widgets/geometry_diagram.dart';
import '../../widgets/premium_solution_panel.dart';
import '../../services/premium_api_service.dart';
import '../../services/geometry_api_service.dart';
import '../../services/api_service.dart';

/// Displays one problem with a simple New / Needs Review / Solved journey.
class ProblemDetailsScreen extends ConsumerStatefulWidget {
  const ProblemDetailsScreen({super.key});

  @override
  ConsumerState<ProblemDetailsScreen> createState() =>
      _ProblemDetailsScreenState();
}

class _ProblemDetailsScreenState extends ConsumerState<ProblemDetailsScreen> {
  bool _autoRetryTriggered = false;
  bool _challengeAdvancePaused = false;
  Timer? _challengeAdvanceTimer;

  @override
  void dispose() {
    _challengeAdvanceTimer?.cancel();
    super.dispose();
  }

  void _continueChallenge() {
    _challengeAdvanceTimer?.cancel();
    if (mounted) Navigator.pop(context, true);
  }

  void _pauseChallengeAdvance() {
    _challengeAdvanceTimer?.cancel();
    if (mounted) setState(() => _challengeAdvancePaused = true);
  }

  ({int? problemId, bool retry, bool dailyChallenge, int? nextProblemId, int? trackId, int? categoryId}) _readArguments() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is int) {
      return (problemId: arguments, retry: false, dailyChallenge: false, nextProblemId: null, trackId: null, categoryId: null);
    }
    if (arguments is Map) {
      final rawId = arguments['problemId'] ?? arguments['id'];
      final id = rawId is int ? rawId : int.tryParse('$rawId');
      return (
        problemId: id,
        retry: arguments['retry'] == true,
        dailyChallenge: arguments['dailyChallenge'] == true,
        nextProblemId: arguments['nextProblemId'] is int ? arguments['nextProblemId'] as int : null,
        trackId: arguments['trackId'] is int ? arguments['trackId'] as int : null,
        categoryId: arguments['categoryId'] is int ? arguments['categoryId'] as int : null,
      );
    }
    return (problemId: null, retry: false, dailyChallenge: false, nextProblemId: null, trackId: null, categoryId: null);
  }

  @override
  Widget build(BuildContext context) {
    final routeArguments = _readArguments();
    final problemId = routeArguments.problemId;
    if (problemId == null) {
      return Scaffold(
        body: AppErrorView(
          message: 'invalid_route_arguments'.tr(),
          onRetry: () => Navigator.maybePop(context),
        ),
      );
    }

    final loggedIn = ref.watch(authProvider.select((state) => state.user != null));
    if (!loggedIn) {
      final ar = context.locale.languageCode == 'ar';
      return Scaffold(
        appBar: AppBar(title: Text('problem_details'.tr())),
        body: MathBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.login_rounded, size: 42),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    ar ? 'سجّل دخولك حتى تحل هذه المسألة' : 'Sign in to solve this problem',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                    child: Text(ar ? 'تسجيل الدخول' : 'Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final state = ref.watch(problemDetailsProvider(problemId));
    final notifier = ref.read(problemDetailsProvider(problemId).notifier);
    final loadedProblem = state.problem.valueOrNull;
    final explicitScope=routeArguments.trackId!=null&&routeArguments.categoryId!=null;
    final selection=!routeArguments.dailyChallenge&&!explicitScope&&loadedProblem!=null
        ?ref.watch(trackSelectionProvider):null;
    final selected=selection?.hasError==false&&selection?.isLoading==false?selection?.valueOrNull:null;
    final selectedTrackId=trackNumber(selected?['TrackId']);
    final trackId=explicitScope?routeArguments.trackId:
        loadedProblem!=null&&trackNumber(selected?['StageId'])==loadedProblem.stageId&&selectedTrackId>0?selectedTrackId:null;
    final categoryId=explicitScope?routeArguments.categoryId:loadedProblem?.categoryId;
    final validScope=trackId!=null&&categoryId!=null&&loadedProblem?.categoryId==categoryId&&!routeArguments.dailyChallenge;
    final nextTrack=validScope
        ?ref.watch(nextTrackProblemProvider((trackId:trackId,categoryId:categoryId,afterProblemId:problemId))):null;
    final candidate=nextTrack?.hasError==false&&!nextTrack!.isLoading?nextTrack.valueOrNull:null;
    if(validScope&&candidate!=null&&!candidate.retry){
      final cache=ref.watch(problemPrefetchProvider);
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(mounted)cache.warm(candidate.id,categoryId,trackId);
      });
    }
    final nextId=validScope?candidate?.id:
        selection?.isLoading==true||selection?.hasError==true||explicitScope?null:routeArguments.nextProblemId;

    if (routeArguments.retry &&
        loadedProblem?.isInErrorNotebook == true &&
        !_autoRetryTriggered &&
        loadedProblem?.hasAttempted == true &&
        loadedProblem?.canRetry == true) {
      _autoRetryTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifier.startRetry();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        // An explicit physical back arrow avoids a second RTL flip.
        leading: Builder(
          builder: (appBarContext) => IconButton(
            tooltip: MaterialLocalizations.of(appBarContext).backButtonTooltip,
            onPressed: () => Navigator.maybePop(appBarContext),
            icon: Icon(
              LayoutUtils.backArrow(appBarContext),
              textDirection: ui.TextDirection.ltr,
            ),
          ),
        ),
        title: Text(
        loadedProblem?.stageName.isNotEmpty == true
            ? loadedProblem!.stageName : 'problem_details'.tr(),
        style: loadedProblem == null ? null : TextStyle(
          color: AppColors.stageForIdentity(
            loadedProblem.stageId, loadedProblem.stageName),
          fontWeight: FontWeight.w800,
        ),
      )),
      body: MathBackground(
        child: state.problem.when(
          loading: () => const AppContentSkeleton(count:4),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppErrorView(
                message: localizedErrorMessage(error),
                onRetry: notifier.load,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(LayoutUtils.backArrow(context), textDirection: ui.TextDirection.ltr),
                label: Text('category_locked_continue_free'.tr()),
              ),
            ],
          ),
          data: (problem) => _ProblemContent(
            problem: problem,
            state: state,
            allowNotebookRetry: routeArguments.retry,
            onOptionChanged: notifier.selectOption,
            isDailyChallenge: routeArguments.dailyChallenge,
            challengeAdvancePaused: _challengeAdvancePaused,
            onPauseChallengeAdvance: _pauseChallengeAdvance,
            onContinueChallenge: _continueChallenge,
            nextTrackKey: validScope?(trackId:trackId,categoryId:categoryId,afterProblemId:problemId):null,
            onNextProblem: !validScope&&nextId==null ? null : () {
              final fresh=validScope?ref.read(nextTrackProblemProvider((trackId:trackId,categoryId:categoryId,afterProblemId:problemId))).valueOrNull:null;
              if(validScope&&fresh==null)return;
              if(fresh!=null&&explicitScope){
                Navigator.pop(context,fresh);
              }else if(fresh!=null){
                Navigator.pushReplacementNamed(context,AppRoutes.problemDetails,arguments:{
                  'problemId':fresh.id,'retry':fresh.retry,
                });
              }else{
                Navigator.pop(context,'nextProblem');
              }
            },
            nextTrackLoading: selection?.isLoading==true||nextTrack?.isLoading==true,
            nextTrackError: selection?.hasError==true||nextTrack?.hasError==true,
            nextTrackExhausted: nextTrack?.hasValue==true&&nextTrack?.isLoading==false&&nextTrack?.hasError==false&&candidate==null,
            onRetryNext: selection?.hasError==true?()=>ref.invalidate(trackSelectionProvider):validScope?()=>ref.invalidate(nextTrackProblemProvider((trackId:trackId,categoryId:categoryId,afterProblemId:problemId))):null,
            onSubmit: () => _runAction(context, () async {
              await notifier.submitAnswer();
              if (!mounted) return;
              if(validScope)ref.invalidate(nextTrackProblemProvider((trackId:trackId,categoryId:categoryId,afterProblemId:problemId)));
            }),
            onResultClosed: () {
              if (!routeArguments.dailyChallenge || !mounted || _challengeAdvancePaused) return;
              if (ref.read(problemDetailsProvider(problemId)).answerResult?.isCorrect == true) {
                _challengeAdvanceTimer?.cancel();
                _challengeAdvanceTimer = Timer(const Duration(seconds:8),_continueChallenge);
              }
            },
            onResultOpened: () => _challengeAdvanceTimer?.cancel(),
            onStartRetry: notifier.startRetry,
            onCancelRetry: notifier.cancelRetry,
            onToggleFavorite: () =>
                _runAction(context, notifier.toggleFavorite),
          ),
        ),
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showMathWorldNotice(context,localizedErrorMessage(error),kind:MathWorldNoticeKind.error);
    }
  }
}

class _ProblemContent extends ConsumerWidget {
  final Problem problem;
  final ProblemDetailsState state;
  final bool allowNotebookRetry;
  final bool isDailyChallenge;
  final bool challengeAdvancePaused;
  final VoidCallback onPauseChallengeAdvance;
  final VoidCallback onContinueChallenge;
  final VoidCallback? onNextProblem;
  final NextTrackProblemKey? nextTrackKey;
  final VoidCallback onResultOpened,onResultClosed;
  final bool nextTrackLoading,nextTrackError,nextTrackExhausted;
  final VoidCallback? onRetryNext;
  final ValueChanged<int?> onOptionChanged;
  final Future<void> Function() onSubmit;
  final VoidCallback onStartRetry;
  final VoidCallback onCancelRetry;
  final VoidCallback onToggleFavorite;

  const _ProblemContent({
    required this.problem,
    required this.state,
    required this.allowNotebookRetry,
    required this.isDailyChallenge,
    required this.challengeAdvancePaused,
    required this.onPauseChallengeAdvance,
    required this.onContinueChallenge,
    required this.onNextProblem,
    required this.nextTrackKey,
    required this.onResultOpened,
    required this.onResultClosed,
    required this.nextTrackLoading,
    required this.nextTrackError,
    required this.nextTrackExhausted,
    required this.onRetryNext,
    required this.onOptionChanged,
    required this.onSubmit,
    required this.onStartRetry,
    required this.onCancelRetry,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = context.locale.languageCode == 'ar';
    final canSelect = state.answerResult == null &&
        (!problem.hasAttempted || state.isRetryMode);
    final solved=state.answerResult?.isCorrect ?? problem.isSolved;
    Future<void> openResult() async {
      if(!context.mounted)return;
      onResultOpened();
      final action=await showDialog<String>(context:context,builder:(dialogContext)=>Consumer(
        builder:(dialogContext,dialogRef,_) {
          final activeState=dialogRef.watch(problemDetailsProvider(problem.id));
          final activeProblem=activeState.problem.valueOrNull;
          if(activeProblem==null||activeState.answerResult==null||activeState.isRetryMode){
            return AlertDialog(content:Text(isArabic?'النتيجة غير متاحة':'Result unavailable'));
          }
    final solution = _solutionText(activeProblem, activeState);
    final structure = !activeState.isRetryMode&&(activeState.answerResult?.isCorrect??activeProblem.isSolved)?activeState.answerResult?.solutionStructure??activeProblem.solutionStructure:null;
    final solved=activeState.answerResult?.isCorrect ?? activeProblem.isSolved;
    final videoUrl = solved && !activeState.isRetryMode
        ? activeState.answerResult?.youtubeSolutionUrl ?? activeProblem.youtubeSolutionUrl
        : null;


          final next=nextTrackKey==null?null:dialogRef.watch(nextTrackProblemProvider(nextTrackKey!));
          final nextLoading=next?.isLoading??nextTrackLoading;
          final nextError=next?.hasError??nextTrackError;
          final hasNext=nextTrackKey==null?onNextProblem!=null:next?.valueOrNull!=null&&!nextLoading&&!nextError;
          return AlertDialog(
            title:Text(solved?(isArabic?'أحسنت! إجابة صحيحة':'Well done! Correct answer'):(isArabic?'حاول مرة أخرى':'Try again')),
            scrollable:true,
            content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              if(solved) Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                for(final color in [AppColors.rewardGold,AppColors.success,Theme.of(dialogContext).colorScheme.primary,AppColors.rewardGold])
                  Padding(padding:const EdgeInsets.all(4),child:TweenAnimationBuilder<double>(tween:Tween(begin:0.6,end:1),duration:MediaQuery.of(dialogContext).disableAnimations?Duration.zero:const Duration(milliseconds:450),builder:(_,value,child)=>Transform.scale(scale:value,child:child),child:Icon(Icons.auto_awesome,color:color,size:25))),
              ]),
              _AnswerResultCard(result:activeState.answerResult!),
              if(solved)...[
                const SizedBox(height:16),
                Text(isArabic?'السؤال':'Question',style:Theme.of(dialogContext).textTheme.titleMedium),
                RichMathText(text:activeProblem.questionText,isArabic:isArabic),
        if (solution.isNotEmpty || structure != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          Card(child:ExpansionTile(
            key:ValueKey(('solution',activeProblem.id,solved)),
            initiallyExpanded:true,
            leading:Icon(Icons.menu_book_outlined,color:Theme.of(context).colorScheme.primary),
            title:Text('detailed_solution'.tr(),style:Theme.of(context).textTheme.titleMedium),
            childrenPadding:const EdgeInsets.fromLTRB(16,0,16,16),
            expandedCrossAxisAlignment:CrossAxisAlignment.stretch,
            children:[solution.trim().isNotEmpty ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final paragraph in solution.split(RegExp(r'\n\s*\n')).where((part) => part.trim().isNotEmpty))
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: RichMathText(
                    text: paragraph.trim(), isArabic: isArabic,
                    style: Theme.of(context).textTheme.bodyLarge,
                  )),
              ],
            ) : structure==null ? const SizedBox.shrink() : Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(isArabic?'الفكرة والقانون':'Idea and formula',style:Theme.of(context).textTheme.titleMedium),
              RichMathText(text:structure.idea,isArabic:isArabic),
              RichMathText(text:structure.formulaLatex,isArabic:isArabic,inline:true,assumeMath:true),
              const SizedBox(height:12),
              Text(isArabic?'خطوات الحل':'Solution steps',style:Theme.of(context).textTheme.titleMedium),
              for(var i=0;i<structure.steps.length;i++) Padding(padding:const EdgeInsets.only(top:6),child:RichMathText(text:'${i+1}. ${structure.steps[i]}',isArabic:isArabic)),
              for(final entry in <(String,String)>[(isArabic?'التعويض':'Substitution',structure.substitution),(isArabic?'النتيجة والوحدة':'Result and unit','${structure.result} ${structure.unit}'),(isArabic?'التحقق':'Verification',structure.verification),(isArabic?'الخطأ الشائع':'Common error',structure.commonError)])...[
                const SizedBox(height:12),Text(entry.$1,style:Theme.of(context).textTheme.titleMedium),
                RichMathText(text:entry.$2,isArabic:isArabic),
              ],
            ])],
          )),
        ],
        if (videoUrl?.trim().isNotEmpty == true && !activeState.isRetryMode) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _openVideo(context, videoUrl!),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text('video_solution'.tr()),
          ),
        ],

                if(solution.isEmpty&&structure==null)Text(isArabic?'الحل التفصيلي غير متوفر.':'Detailed solution unavailable.'),
              ]else ...[
                const SizedBox(height:12),
                _DeferredHintSection(key:ValueKey((activeProblem.id,activeProblem.practiceScopeId)),problemId:activeProblem.id,practiceScopeId:activeProblem.practiceScopeId,isArabic:isArabic),
              ],
              if(solved&&!isDailyChallenge)...[
                if(nextLoading)Text(isArabic?'جارٍ تجهيز المسألة التالية…':'Preparing the next problem…')
                else if(nextError)OutlinedButton(onPressed:onRetryNext,child:Text(isArabic?'إعادة تحميل المسألة التالية':'Retry loading the next problem'))
                else if(!hasNext&&(nextTrackKey!=null||nextTrackExhausted))Text(isArabic?'لا توجد مسائل أخرى غير محلولة ومتاحة في هذه الفئة.':'No other available unsolved problems in this topic.'),
              ],
              if(solved&&isDailyChallenge&&!challengeAdvancePaused)OutlinedButton(onPressed:(){onPauseChallengeAdvance();Navigator.pop(dialogContext,'review');},child:Text(isArabic?'إيقاف الانتقال التلقائي':'Pause auto-advance')),
            ]),
            actions:[
              TextButton(onPressed:()=>Navigator.pop(dialogContext),child:Text(isArabic?'إغلاق':'Close')),
              if(!isDailyChallenge)TextButton(onPressed:()=>Navigator.pop(dialogContext,'back'),child:Text('back_to_problems'.tr())),
              if(!solved&&activeProblem.canRetry)FilledButton(onPressed:()=>Navigator.pop(dialogContext,'retry'),child:Text(isArabic?'إعادة المحاولة':'Try again')),
              if(solved&&isDailyChallenge)FilledButton(onPressed:()=>Navigator.pop(dialogContext,'challenge'),child:Text(isArabic?'متابعة التحدي':'Continue challenge')),
              if(solved&&!isDailyChallenge&&hasNext)FilledButton.icon(onPressed:()=>Navigator.pop(dialogContext,'next'),icon:LayoutUtils.forwardIcon(dialogContext),label:Text(isArabic?'المسألة التالية':'Next problem')),
            ],
          );
        },
      ));
      if(!context.mounted)return;
      if(action=='retry')onStartRetry();
      else if(action=='next')onNextProblem?.call();
      else if(action=='challenge')onContinueChallenge();
      else if(action=='back')Navigator.maybePop(context);
      else if(action!='review')onResultClosed();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        _ProblemHeader(
          problem: problem,
          isFavoriteBusy: state.isFavoriteBusy,
          onToggleFavorite: onToggleFavorite,
        ),
        if (problem.hasAttempted) ...[
          const SizedBox(height: AppSpacing.lg),
          _LearningSummaryCard(problem: problem),
        ],
        if (state.isRetryMode) ...[
          const SizedBox(height: AppSpacing.lg),
          _RetryModeBanner(onCancel: onCancelRetry),
        ],
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: RichMathText(
            text: problem.questionText,
            isArabic: isArabic,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (problem.hasDiagram != false)
          _OptionalProblemDiagram(problemId: problem.id, isArabic: isArabic),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'choose_answer'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        RadioGroup<int>(
          groupValue: state.selectedOptionId,
          onChanged: canSelect && !state.isSubmitting ? onOptionChanged : (_) {},
          child: Column(
            children: [
              for (var index = 0; index < problem.options.length; index++) ...[
                _AnswerOptionCard(
                  option: problem.options[index],
                  isArabic: isArabic,
                  isSelected:
                      state.selectedOptionId == problem.options[index].id,
                  isCorrect: _isCorrectOption(problem.options[index], state),
                  isWrong: _isWrongOption(problem.options[index], state),
                  enabled: canSelect && !state.isSubmitting,
                ),
                if (index < problem.options.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        if (canSelect) ...[
          const SizedBox(height: AppSpacing.xl),
          PremiumButton(
            onPressed: state.selectedOptionId == null ||
                    state.isSubmitting
                ? null
                : () async {
                    await onSubmit();
                    if(!context.mounted)return;
                    if(ref.read(problemDetailsProvider(problem.id)).answerResult!=null)await openResult();
                  },
            label: state.isRetryMode
                ? 'submit_training_answer'.tr()
                : 'submit_answer'.tr(),
            // A checkmark denotes submitting an answer in both RTL and LTR.
            // A paper-plane/send arrow misleadingly points the wrong way in Arabic.
            trailingIcon: Icons.check_circle_outline_rounded,
            isLoading: state.isSubmitting,
            expand: true,
          ),
        ],
        if (state.answerResult != null && !state.isRetryMode) ...[
          const SizedBox(height:AppSpacing.lg),
          OutlinedButton.icon(onPressed:openResult,icon:Icon(solved?Icons.check_circle_outline:Icons.lightbulb_outline),label:Text(solved?(isArabic?'عرض الحل والنتيجة':'View result and solution'):(isArabic?'التلميحات وإعادة المحاولة':'Hints and retry'))),
        ],
        if ((allowNotebookRetry || !isDailyChallenge || state.answerResult?.isCorrect == false) && problem.hasAttempted &&
            problem.isInErrorNotebook && problem.canRetry &&
            !state.isRetryMode &&
            !state.isSubmitting) ...[
          const SizedBox(height: AppSpacing.lg),
          PremiumButton(
            onPressed: onStartRetry,
            label: 'train_again'.tr(),
            leadingIcon: Icons.model_training_rounded,
            expand: true,
          ),
        ],
        if (state.answerResult == null) ...[
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.list_alt_rounded),
            label: Text('back_to_problems'.tr()),
          ),
        ],
      ],
    );
  }

  bool _isCorrectOption(Option option, ProblemDetailsState state) {
    final result = state.answerResult;
    if (result == null) {
      return false;
    }
    if (result.correctOptionId != null) {
      return result.correctOptionId == option.id;
    }

    final correctText = result.correctOptionText;
    if (correctText != null && correctText.trim().isNotEmpty) {
      return _normalizeMathText(correctText) ==
          _normalizeMathText(option.latexCode);
    }

    return result.isCorrect && state.selectedOptionId == option.id;
  }

  String _normalizeMathText(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'^\$+|\$+$'), '')
        .replaceAll(RegExp(r'\s+'), '');
  }

  bool _isWrongOption(Option option, ProblemDetailsState state) {
    final result = state.answerResult;
    return result != null &&
        !result.isCorrect &&
        state.selectedOptionId == option.id;
  }

  String _solutionText(Problem problem, ProblemDetailsState state) {
    if (state.isRetryMode && state.answerResult == null) {
      return '';
    }
    if(!(state.answerResult?.isCorrect??problem.isSolved))return '';
    final resultSolution = state.answerResult?.detailedSolution.trim() ?? '';
    if (resultSolution.isNotEmpty) {
      return resultSolution;
    }
    if (problem.isSolved) {
      return problem.detailedSolution?.trim() ?? '';
    }
    return '';
  }

  Future<void> _openVideo(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    final isSupportedScheme =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');

    var opened = false;
    if (isSupportedScheme) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }

    if (!opened && context.mounted) {
      showMathWorldNotice(context,'unable_to_open_link'.tr(),kind:MathWorldNoticeKind.error);
    }
  }
}

/// Defer entitlement and hint reads until the learner actually expands hints.
class _DeferredHintSection extends StatefulWidget{
  final int problemId;
  final int? practiceScopeId;
  final bool isArabic;
  const _DeferredHintSection({super.key,required this.problemId,this.practiceScopeId,required this.isArabic});
  @override State<_DeferredHintSection> createState()=>_DeferredHintSectionState();
}
class _DeferredHintSectionState extends State<_DeferredHintSection>{
  bool _opened=false;
  @override Widget build(BuildContext context)=>Card(child:ExpansionTile(
    leading:const Icon(Icons.lightbulb_outline_rounded,color:AppColors.rewardGold),
    title:Text(widget.isArabic?'التلميحات':'Hints'),
    maintainState:_opened,
    onExpansionChanged:(open){if(open&&!_opened)setState(()=>_opened=true);},
    children:[if(_opened)PremiumHintPanel(problemId:widget.problemId,practiceScopeId:widget.practiceScopeId,service:PremiumApiService(ApiService()),isArabic:widget.isArabic)],
  ));
}

class _LearningSummaryCard extends StatelessWidget {
  final Problem problem;
  const _LearningSummaryCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    final solved = problem.isSolved;
    final needsReview = !solved && problem.hasAttempted;
    final color = solved ? AppColors.success :
        needsReview ? AppColors.error : AppColors.brandPurple;
    final ar = context.locale.languageCode == 'ar';
    return GlassCard(
      child: Row(children: [
        Icon(solved ? Icons.check_circle_outline_rounded :
          needsReview ? Icons.error_outline_rounded : Icons.circle_outlined,
          color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(
          solved ? (ar ? 'محلولة بنجاح' : 'Solved successfully') :
          needsReview ? (ar ? 'تحتاج مراجعة' : 'Needs review') :
          (ar ? 'جديدة' : 'New'),
          style: Theme.of(context).textTheme.titleMedium,
        )),
      ]),
    );
  }
}

class _RetryModeBanner extends StatelessWidget {
  final VoidCallback onCancel;

  const _RetryModeBanner({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      color: AppColors.brandPurple.withValues(alpha: 0.08),
      border: BorderSide(
        color: AppColors.brandPurple.withValues(alpha: 0.28),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.model_training_rounded,
            color: AppColors.brandViolet,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'training_mode'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('training_mode_desc'.tr()),
              ],
            ),
          ),
          TextButton(onPressed: onCancel, child: Text('cancel'.tr())),
        ],
      ),
    );
  }
}

class _ProblemHeader extends StatelessWidget {
  final Problem problem;
  final bool isFavoriteBusy;
  final VoidCallback onToggleFavorite;

  const _ProblemHeader({
    required this.problem,
    required this.isFavoriteBusy,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              iconSize: 28,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: AppColors.error.withValues(alpha: 0.08),
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: isFavoriteBusy ? null : onToggleFavorite,
              tooltip: problem.isFavorite
                  ? 'remove_from_favorites'.tr()
                  : 'add_to_favorites'.tr(),
              icon: isFavoriteBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: AppInlineLoader(size:18),
                    )
                  : Icon(
                      problem.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: AppColors.error,
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _InfoPill(
              icon: Icons.category_outlined,
              label: problem.categoryName,
              color: AppColors.stageForIdentity(problem.stageId, problem.stageName),
            ),
            _InfoPill(
              icon: Icons.star_rounded,
              label: 'points_value'.tr(
                namedArgs: {'count': '${problem.points}'},
              ),
              color: AppColors.pointsGold(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnswerOptionCard extends StatelessWidget {
  final Option option;
  final bool isArabic;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool enabled;

  const _AnswerOptionCard({
    required this.option,
    required this.isArabic,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stateColor = isCorrect
        ? AppColors.success
        : isWrong
            ? AppColors.error
            : isSelected
                ? scheme.primary
                : scheme.outline;

    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: stateColor.withValues(
          alpha: isCorrect || isWrong || isSelected ? 0.09 : 0.0,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: stateColor,
          width: isCorrect || isWrong || isSelected ? 1.7 : 1,
        ),
      ),
      child: RadioListTile<int>(
        value: option.id,
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        controlAffinity: ListTileControlAffinity.leading,
        secondary: isCorrect
            ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
            : isWrong
                ? const Icon(Icons.cancel_rounded, color: AppColors.error)
                : null,
        title: Semantics(
          value: isCorrect
              ? (isArabic ? 'إجابة صحيحة' : 'Correct answer')
              : isWrong
                  ? (isArabic ? 'إجابة خاطئة' : 'Incorrect answer')
                  : isSelected
                      ? (isArabic ? 'الإجابة المختارة' : 'Selected answer')
                      : null,
          child: RichMathText(
          text: option.latexCode,
          isArabic: isArabic,
          inline: true,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: effectiveColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: icon == Icons.star_rounded ? effectiveColor : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnswerResultCard extends StatelessWidget {
  final AnswerResult result;

  const _AnswerResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final resultColor = result.isCorrect ? AppColors.success : AppColors.error;
    return GlassCard(
      color: resultColor.withValues(alpha: 0.08),
      border: BorderSide(color: resultColor.withValues(alpha: 0.30)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.isCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: resultColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.isCorrect
                      ? 'correct_answer'.tr()
                      : 'wrong_answer'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: resultColor,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  result.isCorrect
                      ? (context.locale.languageCode == 'ar'
                          ? 'انتقلت المسألة إلى المحلولة بنجاح.'
                          : 'This problem is now solved successfully.')
                      : (context.locale.languageCode == 'ar'
                          ? 'المسألة الآن في دفتر الأخطاء. يمكنك مراجعتها وحلها من هناك.'
                          : 'This problem is in your error notebook. Review and solve it there.'),
                ),
                if (result.pointsEarned > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'points_earned_value'.tr(
                      namedArgs: {'count': '${result.pointsEarned}'},
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.pointsGold(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagram is loaded separately so older problem payloads remain compatible.
class _OptionalProblemDiagram extends StatefulWidget {
  const _OptionalProblemDiagram({required this.problemId, required this.isArabic});
  final int problemId;
  final bool isArabic;

  @override
  State<_OptionalProblemDiagram> createState() => _OptionalProblemDiagramState();
}

class _OptionalProblemDiagramState extends State<_OptionalProblemDiagram> {
  late Future<Map<String, dynamic>?> _diagram;

  @override
  void initState() {
    super.initState();
    _diagram = GeometryApiService(ApiService()).getDiagram(widget.problemId);
  }

  @override
  void didUpdateWidget(covariant _OptionalProblemDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problemId != widget.problemId) {
      _diagram = GeometryApiService(ApiService()).getDiagram(widget.problemId);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: _diagram,
    builder: (context, snapshot) {
      final scene = snapshot.data;
      if (scene == null) return const SizedBox.shrink();
      // GeometryDiagram supplies the same bordered figure and caption as the web.
      // Avoid nesting an additional glass card around it on small screens.
      return GeometryDiagram(scene: scene, isArabic: widget.isArabic);
    },
  );
}
