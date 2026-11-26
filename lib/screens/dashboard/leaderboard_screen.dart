import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_states.dart';
import '../../widgets/math_background.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/mathworld_pagination.dart';
import '../../widgets/mobile_section.dart';

/// Read-only stage leaderboard, with anonymous peers and the learner's own rank.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _period = 'all';
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final stageId = ref.watch(authProvider).user?.currentStageId;
    final language = context.locale.languageCode;
    final isArabic = language == 'ar';

    if (stageId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('leaderboard_title'.tr())),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('leaderboard_choose_stage'.tr()),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.learningStage),
                child: Text('learning_stage'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final filter = (stageId: stageId, period: _period, page: _page);
    final result = ref.watch(leaderboardProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: Text('leaderboard_title'.tr()),
      ),
      body: MathBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.refresh(leaderboardProvider(filter).future).then((_) {}),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 32,
              ),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _periodChip('all', 'leaderboard_all'),
                    _periodChip('weekly', 'leaderboard_weekly'),
                    _periodChip('monthly', 'leaderboard_monthly'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                result.when(
                  skipLoadingOnRefresh:false,skipLoadingOnReload:false,
                  loading: () => const AppLoadingView(mode:AppLoadingMode.filter),
                  error: (error, _) => GlassCard(
                    child: Column(
                      children: [
                        Text(localizedErrorMessage(error)),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(leaderboardProvider(filter)),
                          child: Text('retry'.tr()),
                        ),
                      ],
                    ),
                  ),
                  data: (leaderboard) {
                    // Recover from an out-of-range page automatically. A
                    // changing leaderboard should never show a false empty
                    // result while valid rankings remain on the first page.
                    if (leaderboard.entries.isEmpty &&
                        leaderboard.totalLearners > 0 &&
                        _page > 1) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _page > 1) {
                          setState(() => _page = 1);
                        }
                      });
                      return const AppLoadingView(mode:AppLoadingMode.filter);
                    }
                    if (leaderboard.entries.isEmpty) {
                      return GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.emoji_events_outlined, size: 36),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              isArabic
                                  ? 'ما في نتائج ترتيب لهالفترة ضمن مرحلتك.'
                                  : 'No ranked solves in your stage for this period.',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              leaderboard.stageParticipants != null &&
                                      leaderboard.stageParticipants! > 0
                                  ? (isArabic
                                      ? 'يوجد ${leaderboard.stageParticipants} طالب في مرحلتك، لكن ما في حلول مسجلة خلال هالفترة. حلّ مسألة لتظهر بالترتيب.'
                                      : '${leaderboard.stageParticipants} learners selected this stage, but nobody has recorded a solve this period. Solve a problem to join the ranking.')
                                  : (isArabic
                                      ? 'حتى يظهر طالب بالمتفوقين، لازم يحل مسألة ويكسب نقاط ضمن المرحلة المحددة.'
                                      : 'A learner appears after earning points by solving a problem in this stage.'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_period != 'all')
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _period = 'all';
                                  _page = 1;
                                }),
                                child: Text('leaderboard_all'.tr()),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                                  context, AppRoutes.home, (route) => false),
                                icon: LayoutUtils.backIcon(context),
                                label: Text(isArabic
                                    ? 'العودة لمتابعة التعلّم'
                                    : 'Return to learning'),
                              ),
                          ],
                        ),
                      );
                    }
                    final maxPage = (leaderboard.totalLearners /
                            (leaderboard.pageSize <= 0 ? 20 : leaderboard.pageSize))
                        .ceil()
                        .clamp(1, 1000000);
                    final top=leaderboard.entries.where((e)=>e.rank>=1&&e.rank<=3).toList();
                    final podium=top.length==3&&top.map((e)=>e.rank).toSet().length==3;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leaderboard.stageName(language),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (leaderboard.stageParticipants != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            isArabic
                                ? 'طلاب المرحلة: ${leaderboard.stageParticipants} · الطلاب المتفوقون: ${leaderboard.totalLearners}'
                                : 'Stage learners: ${leaderboard.stageParticipants} · Ranked solvers: ${leaderboard.totalLearners}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (leaderboard.myRank != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Text(
                              '${'leaderboard_my_rank'.tr()}: #${leaderboard.myRank}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        if(podium)...[
                          const SizedBox(height:16),
                          MobilePanel(child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
                            for(final rank in [2,1,3])Expanded(child:Builder(builder:(context){
                              final entry=top.firstWhere((e)=>e.rank==rank);
                              final color=rank==1?AppColors.rewardGold:rank==2?const Color(0xFF8491A3):const Color(0xFFB87333);
                              return Semantics(label:'#$rank · ${_peerDisplayName(entry.displayName,isArabic)} · ${entry.points}',child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:Column(mainAxisSize:MainAxisSize.min,children:[
                                if(rank==1)const MobileMedal(icon:Icons.emoji_events_rounded,size:52)
                                else Icon(Icons.workspace_premium_rounded,color:color,size:42),
                                const SizedBox(height:8),Text('#$rank',style:const TextStyle(fontWeight:FontWeight.w800)),
                                Text(_peerDisplayName(entry.displayName,isArabic),textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.labelMedium),
                                Text('${entry.points}',style:TextStyle(color:AppColors.pointsGold(context),fontWeight:FontWeight.w800)),
                                Text('${entry.solvedProblems} ${'leaderboard_solved'.tr()}',textAlign:TextAlign.center,style:Theme.of(context).textTheme.labelSmall),
                                if(entry.isCurrentUser)Icon(Icons.verified_rounded,color:Theme.of(context).colorScheme.primary,size:17),
                                const SizedBox(height:8),Container(height:rank==1?44:28,width:double.infinity,decoration:BoxDecoration(color:color.withValues(alpha:.16),borderRadius:BorderRadius.circular(8))),
                              ])));
                            })),
                          ])),
                          const SizedBox(height:16),
                        ],
                        ...leaderboard.entries.where((entry)=>!podium||entry.rank>3).map((entry) {
                          final theme = Theme.of(context);
                          final scheme = theme.colorScheme;
                          final dark = theme.brightness == Brightness.dark;
                          // Medal colors depend on the actual global rank,
                          // not on this page's position in the result list.
                          final Color? medalColor = switch (entry.rank) {
                            1 => AppColors.rewardGold, // Gold
                            2 => const Color(0xFF8491A3), // Silver
                            3 => const Color(0xFFB87333), // Bronze
                            _ => null,
                          };
                          final cardBackground = entry.isCurrentUser
                              ? (dark
                                  ? const Color(0xFF34234A)
                                  : const Color(0xFFF0E8FF))
                              : medalColor == null
                                  ? scheme.surface
                                  : Color.alphaBlend(
                                      medalColor.withValues(alpha: dark ? 0.18 : 0.14),
                                      scheme.surface,
                                    );
                          final cardBorder = entry.isCurrentUser
                              ? BorderSide(
                                  color: dark
                                      ? const Color(0xFFC5A4FF)
                                      : AppColors.brandPurple,
                                  width: 1.8,
                                )
                              : BorderSide(
                                  color: medalColor?.withValues(alpha: 0.70) ??
                                      scheme.outline.withValues(alpha: 0.65),
                                );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: GlassCard(
                              color: cardBackground,
                              border: cardBorder,
                              padding:const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 19,
                                    backgroundColor: medalColor == null
                                        ? scheme.surfaceContainerHighest
                                        : medalColor.withValues(alpha: dark ? 0.32 : 0.26),
                                    foregroundColor: medalColor == null
                                        ? scheme.onSurface
                                        : (dark
                                            ? scheme.onSurface
                                            : const Color(0xFF332018)),
                                    child: medalColor == null
                                        ? Text('${entry.rank}',
                                            style: const TextStyle(fontWeight: FontWeight.w800))
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.workspace_premium_rounded,
                                                  size: 20, color: medalColor),
                                              Text('${entry.rank}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 12,
                                                      height: 1.0)),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _peerDisplayName(entry.displayName, isArabic),
                                          style: TextStyle(
                                            fontWeight: entry.isCurrentUser
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        if (entry.isCurrentUser)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              isArabic ? 'هذا ترتيبك' : 'Your ranking',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: dark
                                                    ? const Color(0xFFD8C0FF)
                                                    : AppColors.brandPurple,
                                              ),
                                            ),
                                          ),
                                        Text.rich(TextSpan(
                                          style: theme.textTheme.bodySmall,
                                          children: [
                                            TextSpan(text: '${entry.solvedProblems} ${'leaderboard_solved'.tr()} · '),
                                            TextSpan(text: '${entry.points} ${'leaderboard_points'.tr()}',
                                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.pointsGold(context))),
                                          ],
                                        )),
                                        Text(
                                          '${entry.firstTryCorrect} ${'leaderboard_first_try'.tr()}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (entry.isCurrentUser)
                                    Icon(Icons.verified_rounded,
                                        color: dark
                                            ? const Color(0xFFD8C0FF)
                                            : AppColors.brandPurple),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: AppSpacing.md),
                        MathWorldPagination(page:_page,pageCount:maxPage,arabic:isArabic,onChanged:(p)=>setState(()=>_page=p)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'leaderboard_privacy'.tr(),
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Use the verified, privacy-shortened name returned by the authenticated
  // leaderboard API, not a numbered or fabricated local label.
  String _peerDisplayName(String name, bool isArabic) {
    final display = name.trim();
    return display.isNotEmpty ? display : (isArabic ? 'طالب' : 'Learner');
  }

  Widget _periodChip(String value, String translationKey) {
    return ChoiceChip(
      label: Text(translationKey.tr()),
      selected: _period == value,
      onSelected: (_) => setState(() {
        _period = value;
        _page = 1;
      }),
    );
  }
}
