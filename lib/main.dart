import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/app_navigator.dart';
import 'config/app_routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await HiveService.init();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: Locale(HiveService.getLanguage()),
      fallbackLocale: const Locale('ar'),
      path: 'assets/translations',
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

/// Configures themes, localization, navigation, and session redirects.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      final newlyExpired =
          next.sessionExpired && previous?.sessionExpired != true;
      if (!newlyExpired) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = AppNavigator.navigatorKey.currentState;
        if (navigator == null) {
          return;
        }

        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('session_expired'.tr())),
        );
        ref.read(authProvider.notifier).consumeSessionExpired();
      });
    });

    return MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      scaffoldMessengerKey: AppNavigator.scaffoldMessengerKey,
      title: 'app_name'.tr(),
      theme: AppTheme.lightTheme(settings.languageCode),
      darkTheme: AppTheme.darkTheme(settings.languageCode),
      themeMode: settings.themeMode,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
    );
  }
}
