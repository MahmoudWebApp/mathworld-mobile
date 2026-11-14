
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../config/app_routes.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/brand_logo.dart';
import '../dashboard/favorites_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../stages/stage_categories_screen.dart';

/// Hosts the primary application sections and the floating navigation bar.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  Timer? _notificationRefresh;

  @override
  void initState() {
    super.initState();
    _notificationRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.invalidate(notificationInboxProvider);
    });
  }

  @override
  void dispose() {
    _notificationRefresh?.cancel();
    super.dispose();
  }

  late final List<Widget> _pages = [
    HomeScreen(onOpenStages: () => setState(() => _selectedIndex = 1)),
    const CurrentStageCategoriesScreen(),
    const FavoritesScreen(embedded: true),
    const SettingsScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const BrandLogo(width: 148, height: 44),
          actions: [
            IconButton(
              tooltip: context.locale.languageCode == 'ar'
                  ? 'الإشعارات' : 'Notifications',
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.notifications);
                if (mounted) ref.invalidate(notificationInboxProvider);
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded),
                  if ((ref.watch(notificationInboxProvider).valueOrNull?.unreadCount ?? 0) > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        height: 9,
                        width: 9,
                        decoration: BoxDecoration(
                          color: AppColors.brandPink,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        // Keep scrollable content above the floating bottom bar.
        extendBody: false,
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.16 : 0.055,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() => _selectedIndex = value);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: 'home'.tr(),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.auto_stories_outlined),
                      selectedIcon: const Icon(Icons.auto_stories_rounded),
                      label: 'active_stage_categories'.tr(),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.favorite_border_rounded),
                      selectedIcon: const Icon(Icons.favorite_rounded),
                      label: 'favorites'.tr(),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings_rounded),
                      label: 'settings'.tr(),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}