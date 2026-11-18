import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../utils/layout_utils.dart';

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
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(leaderboardProvider(filter)),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'retry'.tr(),
          ),
        ],
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
                Text(
                  isArabic
                      ? 'الترتيب يعرض طلاباً حلّوا مسائل فعلياً في مرحلتك. أسماء الآخرين مختصرة أو مخفية للخصوصية، وليست أسماء حسابات أُنشئت للترتيب.'
                      : 'Rankings reflect real solved problems in your stage. Other learners have abbreviated or hidden names for privacy; ranks do not create accounts.',
                  style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
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
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
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
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: CircularProgressIndicator(),
                        ),
                      );
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
                        ...leaderboard.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: GlassCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  child: Text('${entry.rank}'),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.isCurrentUser
                                            ? (isArabic ? 'أنت' : 'You')
                                            : _peerDisplayName(entry.displayName, isArabic),
                                        style: TextStyle(
                                          fontWeight: entry.isCurrentUser
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${entry.solvedProblems} ${'leaderboard_solved'.tr()} · '
                                        '${entry.points} ${'leaderboard_points'.tr()}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        '${entry.firstTryCorrect} ${'leaderboard_first_try'.tr()}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (entry.isCurrentUser)
                                  Icon(Icons.verified_rounded,
                                      color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        )),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              onPressed: _page > 1
                                  ? () => setState(() => _page--)
                                  : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LayoutUtils.previousPageIcon(context, size: 18),
                                  const SizedBox(width: 5),
                                  Text('leaderboard_previous'.tr()),
                                ],
                              ),
                            ),
                            Text('$_page / $maxPage'),
                            OutlinedButton(
                              onPressed: _page < maxPage
                                  ? () => setState(() => _page++)
                                  : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('leaderboard_next'.tr()),
                                  const SizedBox(width: 5),
                                  LayoutUtils.nextPageIcon(context, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  // Older API versions returned numbered aliases such as "Learner #1".
  // Explain their anonymity rather than making them look like fake accounts.
  String _peerDisplayName(String name, bool isArabic) {
    final alias = RegExp(r'^(Learner|متعلم)\\s*#\\d+
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
, caseSensitive: false);
    if (alias.hasMatch(name.trim())) {
      return isArabic
          ? 'طالب مشارك · الاسم مخفي'
          : 'Participating learner · name hidden';
    }
    return name;
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
