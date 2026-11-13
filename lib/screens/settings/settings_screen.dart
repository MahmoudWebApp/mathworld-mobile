import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/constants.dart';
import '../../config/design_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/google_identity_service.dart';
import '../../core/utils/error_message.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

/// Displays appearance, language, legal, and account preferences.
class SettingsScreen extends ConsumerWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final content = MathBackground(
      showSymbols: false,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 132),
          children: [
            if (embedded) ...[
              Text(
                'settings'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text('settings_subtitle'.tr()),
              const SizedBox(height: 24),
            ],
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
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text('learning_stage'.tr()),
                subtitle: Text('change_learning_stage'.tr()),
                trailing: LayoutUtils.forwardIcon(context),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.learningStage,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (GoogleIdentityService.available) ...[
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text('link_google'.tr()),
                  subtitle: Text('link_google_desc'.tr()),
                  trailing: const Icon(Icons.link_rounded),
                  onTap: () async {
                    try {
                      await ref.read(authProvider.notifier).linkGoogle();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('google_linked'.tr())),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(localizedErrorMessage(error))),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
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
          ],
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
