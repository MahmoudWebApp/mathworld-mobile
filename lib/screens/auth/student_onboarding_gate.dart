import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_envelope.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learning_tracks_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/stages_provider.dart';
import '../../widgets/stage_math_glyph.dart';

final studentOnboardingProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final account = ref.watch(
    authProvider.select((state) => (state.user?.id, state.user?.role)),
  );
  if (account.$1 == null || account.$2 != 'Student') return 'SignedOut';
  final response = await ref.watch(apiClientProvider).get('/users/onboarding');
  final step = ApiEnvelope.map(response.data)['NextStep'];
  if (step is String &&
      const [
        'VerifyEmail',
        'SelectStage',
        'SelectTrack',
        'Complete',
      ].contains(step)) {
    return step;
  }
  throw const AppException(
    type: AppExceptionType.invalidResponse,
    messageKey: 'invalid_response',
  );
});

class StudentOnboardingGate extends ConsumerWidget {
  const StudentOnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = context.locale.languageCode == 'ar';
    return ref
        .watch(studentOnboardingProvider)
        .when(
          skipLoadingOnRefresh: false,
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ar
                        ? 'تعذّر التحقق من إعداد الحساب'
                        : 'Could not check account setup',
                  ),
                  FilledButton(
                    onPressed: () => ref.invalidate(studentOnboardingProvider),
                    child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (step) => step == 'Complete'
              ? child
              : _SetupScreen(key: ValueKey(step), step: step),
        );
  }
}

class _SetupScreen extends ConsumerStatefulWidget {
  const _SetupScreen({super.key, required this.step});

  final String step;

  @override
  ConsumerState<_SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<_SetupScreen> {
  final _code = TextEditingController();
  int? _selectedStage;
  int? _selectedTrack;
  bool _busy = false;
  bool _noticeIsError = false;
  String? _notice;

  bool get _ar => context.locale.languageCode == 'ar';
  String _text(String ar, String en) => _ar ? ar : en;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _perform(
    Future<void> Function() action, {
    String? success,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
      _noticeIsError = false;
    });
    try {
      await action();
      if (mounted && success != null) setState(() => _notice = success);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _noticeIsError = true;
        _notice = switch (error) {
          AppException(statusCode: 429) => _text(
            'انتظر قليلاً ثم حاول مجدداً.',
            'Wait a moment and try again.',
          ),
          AppException(statusCode: 503) => _text(
            'الخدمة غير متاحة حالياً. حاول مجدداً بعد قليل.',
            'The service is temporarily unavailable. Try again shortly.',
          ),
          _ => _text(
            'تعذّر إتمام العملية. حاول مجدداً.',
            'Could not complete the action. Try again.',
          ),
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirmCode() {
    final code = _code.text;
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) return;
    FocusScope.of(context).unfocus();
    _perform(() async {
      try {
        await ref
            .read(apiClientProvider)
            .post(
              '/auth/email-verification/confirm-code',
              data: {'Code': code},
            );
      } on AppException catch (error) {
        if (error.statusCode != 400) rethrow;
        if (!mounted) return;
        setState(() {
          _noticeIsError = true;
          _notice = _text(
            'الرمز غير صالح أو انتهت صلاحيته. جرّب الرمز الأحدث أو اطلب رمزاً جديداً.',
            'The code is invalid or expired. Use the latest code or request a new one.',
          );
        });
        return;
      }
      if (mounted) ref.invalidate(studentOnboardingProvider);
    });
  }

  void _sendCode() => _perform(
    () async {
      final response = await ref
          .read(apiClientProvider)
          .post(
            '/auth/email-verification/request',
            data: {'Language': context.locale.languageCode},
          );
      if (!mounted) return;
      if (ApiEnvelope.map(response.data)['AlreadyVerified'] == true) {
        ref.invalidate(studentOnboardingProvider);
      } else {
        _code.clear();
      }
    },
    success: _text(
      'تم طلب رمز جديد. تحقّق من بريدك خلال لحظات.',
      'A new code was requested. Check your inbox in a moment.',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final verify = widget.step == 'VerifyEmail';
    final stage = widget.step == 'SelectStage';
    final signedOut = widget.step == 'SignedOut';
    final stageId = _selectedStage ?? user?.currentStageId;
    final showStages =
        stage || (!verify && !signedOut && user?.currentStageId == null);
    final showTracks = !verify && !stage && !signedOut && stageId != null;
    final language = context.locale.languageCode;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = switch (widget.step) {
      'VerifyEmail' => _text('فعّل حسابك', 'Verify your account'),
      'SelectStage' => _text(
        'اختر مرحلتك الدراسية',
        'Choose your learning stage',
      ),
      'SelectTrack' => _text(
        'اختر صفّك أو مساقك',
        'Choose your grade or course',
      ),
      _ => _text('سجّل دخولك للمتابعة', 'Sign in to continue'),
    };

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MathWorld'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 24),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          verify
                              ? Icons.mark_email_unread_outlined
                              : Icons.school_outlined,
                          color: colors.onPrimaryContainer,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  if (verify) ...[
                    Text(
                      _text(
                        'أدخل الرمز المكوّن من ٦ أرقام الذي أُرسل إلى بريدك الإلكتروني.',
                        'Enter the six-digit code sent to your email.',
                      ),
                    ),
                    if (user?.email.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          user!.email,
                          textDirection: TextDirection.ltr,
                          textAlign: _ar ? TextAlign.right : TextAlign.left,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    const SizedBox(height: 24),
                    AutofillGroup(
                      child: TextField(
                        controller: _code,
                        enabled: !_busy,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (_, next) => next.copyWith(
                              text: _normalizeDigits(next.text),
                            ),
                          ),
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          labelText: _text('رمز التفعيل', 'Verification code'),
                          border: const OutlineInputBorder(),
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          letterSpacing: 8,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _confirmCode(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy || _code.text.length != 6
                          ? null
                          : _confirmCode,
                      child: Text(
                        _text('تفعيل ومتابعة', 'Verify and continue'),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _sendCode,
                      child: Text(_text('إرسال رمز جديد', 'Send a new code')),
                    ),
                  ],
                  if (showStages) ...[
                    Text(
                      _text(
                        'تحدد مرحلتك الفئات والمسائل التي تظهر لك.',
                        'Your stage determines the topics and problems you see.',
                      ),
                    ),
                    const SizedBox(height: 18),
                    ref
                        .watch(stagesProvider)
                        .when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) =>
                              _retry(() => ref.invalidate(stagesProvider)),
                          data: (stages) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (stages.isEmpty)
                                Text(
                                  _text(
                                    'لا توجد مراحل دراسية متاحة حالياً.',
                                    'No learning stages are available yet.',
                                  ),
                                ),
                              for (final item in stages)
                                _ChoiceCard(
                                  title: item.getName(language),
                                  description: item.getDescription(language),
                                  leading: StageMathGlyph(
                                    stageOrder: item.order,
                                    color: colors.primary,
                                    size: 32,
                                  ),
                                  selected: stageId == item.id,
                                  onTap: _busy
                                      ? null
                                      : () => setState(() {
                                          _selectedStage = item.id;
                                          _selectedTrack = null;
                                        }),
                                ),
                              if (stage) ...[
                                const SizedBox(height: 10),
                                FilledButton(
                                  onPressed:
                                      _busy ||
                                          stageId == null ||
                                          !stages.any(
                                            (item) => item.id == stageId,
                                          )
                                      ? null
                                      : () {
                                          _perform(() async {
                                            await ref
                                                .read(authProvider.notifier)
                                                .chooseLearningStage(stageId);
                                            if (mounted)
                                              ref.invalidate(
                                                studentOnboardingProvider,
                                              );
                                          });
                                        },
                                  child: Text(_text('متابعة', 'Continue')),
                                ),
                              ],
                            ],
                          ),
                        ),
                  ],
                  if (showTracks) ...[
                    if (!showStages)
                      Text(
                        _text(
                          'اختر المستوى لتبدأ بمسائل تناسب دراستك.',
                          'Choose a level to start with problems that match your studies.',
                        ),
                      ),
                    const SizedBox(height: 18),
                    ref
                        .watch(publishedTracksProvider(stageId))
                        .when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => _retry(
                            () => ref.invalidate(
                              publishedTracksProvider(stageId),
                            ),
                          ),
                          data: (catalog) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (catalog.items.isEmpty)
                                Text(
                                  _text(
                                    'لا توجد صفوف أو مساقات منشورة حالياً.',
                                    'No published grades or courses yet.',
                                  ),
                                ),
                              for (final item in catalog.items)
                                _ChoiceCard(
                                  title: trackText(item, 'Name', _ar),
                                  description: _gradeAge(item),
                                  leading: Icon(
                                    Icons.menu_book_outlined,
                                    color: colors.primary,
                                  ),
                                  selected:
                                      _selectedTrack == trackNumber(item['Id']),
                                  onTap: _busy
                                      ? null
                                      : () => setState(
                                          () => _selectedTrack = trackNumber(
                                            item['Id'],
                                          ),
                                        ),
                                ),
                              const SizedBox(height: 10),
                              FilledButton(
                                onPressed:
                                    _busy ||
                                        _selectedTrack == null ||
                                        !catalog.items.any(
                                          (item) =>
                                              trackNumber(item['Id']) ==
                                              _selectedTrack,
                                        )
                                    ? null
                                    : () => _perform(() async {
                                        await ref
                                            .read(apiClientProvider)
                                            .put(
                                              '/users/learning-track',
                                              data: {'TrackId': _selectedTrack},
                                            );
                                        if (!mounted) return;
                                        ref.invalidate(trackSelectionProvider);
                                        ref.invalidate(
                                          studentOnboardingProvider,
                                        );
                                        await ref
                                            .read(authProvider.notifier)
                                            .refreshProfile();
                                      }),
                                child: Text(
                                  _text('ابدأ التعلّم', 'Start learning'),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                  if (signedOut)
                    FilledButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (_) => false,
                      ),
                      child: Text(_text('تسجيل الدخول', 'Sign in')),
                    ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: LinearProgressIndicator(),
                    ),
                  if (_notice case final notice?)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          notice,
                          style: TextStyle(
                            color: _noticeIsError
                                ? colors.error
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  if (user != null)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _perform(() async {
                              await ref.read(authProvider.notifier).logout();
                              if (mounted)
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.login,
                                  (_) => false,
                                );
                            }),
                      child: Text(_text('تسجيل الخروج', 'Sign out')),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _retry(VoidCallback onPressed) => OutlinedButton(
    onPressed: onPressed,
    child: Text(_text('تعذّر التحميل. أعد المحاولة', 'Could not load. Retry')),
  );

  String? _gradeAge(Map<String, dynamic> item) {
    final match = RegExp(
      r'^grade-(\d+)$',
    ).firstMatch(item['Code']?.toString() ?? '');
    final grade = int.tryParse(match?.group(1) ?? '');
    if (grade == null || grade < 1 || grade > 12) return null;
    return _text(
      'العمر التقريبي ${grade + 5}–${grade + 6} سنة',
      'Typical age ${grade + 5}–${grade + 6} years',
    );
  }
}

String _normalizeDigits(String value) {
  const digits = '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹';
  return value.replaceAllMapped(RegExp('[$digits]'), (match) {
    return (digits.indexOf(match[0]!) % 10).toString();
  });
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.description,
    required this.leading,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? description;
  final Widget leading;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final subtitle = description?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          selected: selected,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: leading,
          title: Text(title),
          subtitle: subtitle == null || subtitle.isEmpty
              ? null
              : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
