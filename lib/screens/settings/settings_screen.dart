import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../widgets/mathworld_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/constants.dart';
import '../../config/design_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stages_provider.dart';
import '../../providers/social_link_status_provider.dart';
import '../../services/google_identity_service.dart';
import '../../core/utils/error_message.dart';
import '../../core/errors/app_exception.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/account_password_dialog.dart';
import '../../widgets/email_preferences_dialog.dart';
import '../../widgets/leaderboard_name_preference.dart';
import '../../widgets/platform_contact_card.dart';

/// Displays appearance, language, legal, and account preferences.
class SettingsScreen extends ConsumerWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentUser = ref.watch(authProvider.select((state) => state.user));
    final googleLinkState = GoogleIdentityService.available && currentUser?.role == 'Student'
        ? ref.watch(googleLinkedProvider)
        : null;
    final stages = ref.watch(stagesProvider).valueOrNull ?? [];
    final stage = stages.where((stage) => stage.id == currentUser?.currentStageId);
    final selectedStage = stage.isNotEmpty
        ? stage.first.getName(context.locale.languageCode)
        : null;

    final content = MathBackground(
      showSymbols: false,
      child: SafeArea(
        bottom: false,
        child: DefaultTabController(
          length: 4,
          child: Column(children: [
            if(embedded) Padding(padding: const EdgeInsets.fromLTRB(16,12,16,8),child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('settings'.tr(),style:Theme.of(context).textTheme.headlineSmall),Icon(Icons.settings_outlined,color:Theme.of(context).colorScheme.primary)])),
            TabBar(isScrollable:true,tabAlignment:TabAlignment.start,tabs:[
              Tab(text:context.locale.languageCode=='ar'?'المظهر واللغة':'Appearance'),
              Tab(text:context.locale.languageCode=='ar'?'التعلّم':'Learning'),
              Tab(text:context.locale.languageCode=='ar'?'الحساب':'Account'),
              Tab(text:context.locale.languageCode=='ar'?'حول التطبيق':'About'),
            ]),
            Expanded(child:TabBarView(children:[
ListView(key: const PageStorageKey('settings-0'),padding:const EdgeInsets.all(16),children:[
            _SectionTitle(title: 'appearance'.tr()),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: RadioGroup<ThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(value);
                  }
                },
                child: const Column(
                  children: [
                    _ThemeTile(
                      value: ThemeMode.system,
                      titleKey: 'theme_system',
                      icon: Icons.settings_suggest_outlined,
                    ),
                    Divider(height: 1, indent: 62),
                    _ThemeTile(
                      value: ThemeMode.light,
                      titleKey: 'theme_light',
                      icon: Icons.light_mode_outlined,
                    ),
                    Divider(height: 1, indent: 62),
                    _ThemeTile(
                      value: ThemeMode.dark,
                      titleKey: 'theme_dark',
                      icon: Icons.dark_mode_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'language'.tr()),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: RadioGroup<String>(
                groupValue: settings.languageCode,
                onChanged: (value) async {
                  if (value == null) {
                    return;
                  }

                  await ref.read(settingsProvider.notifier).setLanguage(value);
                  if (!context.mounted) {
                    return;
                  }
                  await context.setLocale(Locale(value));
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'ar',
                      title: Text('language_arabic'.tr()),
                      secondary: const Icon(Icons.translate_rounded),
                    ),
                    const Divider(height: 1, indent: 62),
                    RadioListTile<String>(
                      value: 'en',
                      title: Text('language_english'.tr()),
                      secondary: const Icon(Icons.language_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
]),
ListView(key: const PageStorageKey('settings-1'),padding:const EdgeInsets.all(16),children:[
            _SectionTitle(title: 'learning_tools'.tr()),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.auto_stories_outlined),
                title: Text('error_notebook'.tr()),
                subtitle: Text('error_notebook_settings_desc'.tr()),
                trailing: LayoutUtils.forwardIcon(context),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.errorNotebook);
                },
              ),
            ),
            if (currentUser?.role == 'Student')
              const SizedBox(height: AppSpacing.md),
            if (currentUser?.role == 'Student')
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(context.locale.languageCode == 'ar'
                      ? (currentUser?.subscriptionType.toLowerCase() == 'premium'
                          ? 'مميزات حسابي' : 'مميزات الحساب')
                      : (currentUser?.subscriptionType.toLowerCase() == 'premium'
                          ? 'My account benefits' : 'Account benefits')),
                  subtitle: Text(context.locale.languageCode == 'ar'
                      ? 'المميزات ورمز التفعيل'
                      : 'Benefits and activation code'),
                  trailing: LayoutUtils.forwardIcon(context),
                  onTap: () => Navigator.pushNamed(
                    context, AppRoutes.premiumBenefits,
                  ),
                ),
              ),
            if (currentUser?.role == 'Student')
              const SizedBox(height: AppSpacing.md),
            if (currentUser?.role == 'Student')
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text('learning_stage'.tr()),
                  subtitle: Text(
                    selectedStage ?? (context.locale.languageCode == 'ar'
                        ? 'اختيار المرحلة' : 'Choose a stage'),
                  ),
                  trailing: LayoutUtils.forwardIcon(context),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.learningStage,
                  ),
                ),
              ),
            if (currentUser?.role == 'Student')
              const SizedBox(height: AppSpacing.md),
            if (currentUser?.role == 'Student')
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.bar_chart_rounded),
                  title: Text(context.locale.languageCode == 'ar'
                      ? (currentUser?.subscriptionType.toLowerCase() == 'premium'
                          ? 'تقريري الشخصي' : 'تقارير متقدمة')
                      : (currentUser?.subscriptionType.toLowerCase() == 'premium'
                          ? 'My progress report' : 'Advanced reports')),
                  subtitle: Text(context.locale.languageCode == 'ar'
                      ? 'إحصائيات المحاولات والنقاط والفئات'
                      : 'Attempts, points and category progress'),
                  trailing: currentUser?.subscriptionType.toLowerCase() == 'premium'
                      ? LayoutUtils.forwardIcon(context)
                      : Tooltip(
                          message: context.locale.languageCode == 'ar'
                              ? 'خاص بحساب Premium' : 'Premium account',
                          child: Icon(Icons.lock_outline_rounded,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                  onTap: currentUser?.subscriptionType.toLowerCase() == 'premium'
                      ? () => Navigator.pushNamed(context, AppRoutes.premiumAnalytics)
                      : null,
                ),
              ),
            const SizedBox(height: 24),
]),
ListView(key: const PageStorageKey('settings-2'),padding:const EdgeInsets.all(16),children:[
            // The linking tile disappears after the API confirms Google.
            // Verification errors still allow retry.
            if (GoogleIdentityService.available &&
                currentUser?.role == 'Student' &&
                googleLinkState?.valueOrNull != true) ...[
              _SectionTitle(
                title: context.locale.languageCode == 'ar'
                    ? 'الحسابات المرتبطة'
                    : 'Connected accounts',
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    googleLinkState?.valueOrNull == true
                        ? Icons.verified_rounded
                        : Icons.account_circle_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(googleLinkState?.valueOrNull == true
                      ? (context.locale.languageCode == 'ar'
                          ? 'Google مرتبط بالحساب'
                          : 'Google account connected')
                      : 'link_google'.tr()),
                  subtitle: Text(googleLinkState?.hasError == true
                      ? (context.locale.languageCode == 'ar'
                          ? 'تعذّر التأكد من الربط. اضغط لإعادة المحاولة.'
                          : 'Could not verify. Tap to retry.')
                      : googleLinkState?.isLoading == true
                          ? (context.locale.languageCode == 'ar'
                              ? 'جاري التحقق من الربط…'
                              : 'Checking connection…')
                          : googleLinkState?.valueOrNull == true
                              ? (context.locale.languageCode == 'ar'
                                  ? 'ما في حاجة لإعادة ربط الحساب.'
                                  : 'No need to connect again.')
                              : 'link_google_desc'.tr()),
                  trailing: googleLinkState?.isLoading == true
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(googleLinkState?.valueOrNull == true
                          ? Icons.check_circle_rounded
                          : googleLinkState?.hasError == true
                              ? Icons.refresh_rounded
                              : Icons.link_rounded),
                  onTap: googleLinkState?.valueOrNull == true ||
                          googleLinkState?.isLoading == true
                      ? null
                      : () async {
                          if (googleLinkState?.hasError == true) {
                            ref.invalidate(googleLinkedProvider);
                            return;
                          }
                          try {
                            await ref.read(authProvider.notifier).linkGoogle();
                            ref.invalidate(googleLinkedProvider);
                            if (!context.mounted) return;
                            showMathWorldNotice(context,'google_linked'.tr(),kind:MathWorldNoticeKind.success);
                          } catch (error) {
                            if (!context.mounted) return;
                            if (error is AppException &&
                                error.type == AppExceptionType.cancelled) return;
                            showMathWorldNotice(context,localizedErrorMessage(error),kind:MathWorldNoticeKind.error);
                          }
                        },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (currentUser != null && currentUser.role == 'Student') ...[
              _SectionTitle(title: context.locale.languageCode == 'ar' ? 'أمان الحساب' : 'Account security'),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: Text(context.locale.languageCode == 'ar' ? 'تغيير كلمة المرور' : 'Change password'),
                  trailing: LayoutUtils.forwardIcon(context),
                  onTap: () async {
                    final changed = await showDialog<bool>(
                      context: context, barrierDismissible: false,
                      builder: (_) => const AccountPasswordDialog(),
                    );
                    if (changed != true || !context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                    showMathWorldNotice(context,context.locale.languageCode=='ar'?'تم تغيير كلمة المرور. سجّل الدخول مجدداً.':'Password changed. Please sign in again.',kind:MathWorldNoticeKind.success);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (currentUser != null && currentUser.role == 'Student') ...[
              LeaderboardNamePreference(key: ValueKey(currentUser.id), userId: currentUser.id),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(context.locale.languageCode == 'ar' ? 'تفضيلات البريد الإلكتروني' : 'Email preferences'),
                  trailing: LayoutUtils.forwardIcon(context),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => EmailPreferencesDialog(userId: currentUser.id),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
]),
ListView(key: const PageStorageKey('settings-3'),padding:const EdgeInsets.all(16),children:[
            _SectionTitle(title: 'about_and_legal'.tr()),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: Text('privacy'.tr()),
                    trailing: LayoutUtils.forwardIcon(context),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.privacy);
                    },
                  ),
                  const Divider(height: 1, indent: 62),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text('about'.tr()),
                    subtitle: Text(
                      'app_version_value'.tr(
                        namedArgs: {'version': AppConstants.appVersion},
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const PlatformContactCard(),
            const SizedBox(height: 24),
            GlassCard(
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withValues(alpha: 0.11),
                  AppColors.error.withValues(alpha: 0.04),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'logout'.tr(),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                trailing: LayoutUtils.forwardIcon(
                  context,
                  color: AppColors.error,
                ),
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (_) => false,
                  );
                },
              ),
            ),
]),
            ])),
          ]),
        ),
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: content,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeMode value;
  final String titleKey;
  final IconData icon;

  const _ThemeTile({
    required this.value,
    required this.titleKey,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: value,
      title: Text(titleKey.tr()),
      secondary: Icon(icon),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}
