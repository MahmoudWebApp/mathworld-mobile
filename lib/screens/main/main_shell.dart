
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../config/app_routes.dart';
import '../../providers/notification_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../providers/student_badges_provider.dart';
import '../../providers/learning_journey_provider.dart';
import '../../providers/learner_presence_provider.dart';
import '../../services/learner_presence_service.dart';
import '../../services/notification_live_updates.dart';
import '../../providers/repositories_provider.dart';
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

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _initialTabApplied = false;
  Timer? _notificationRefresh;
  bool _isAppResumed = true;
  bool _presenceInFlight = false;
  late final LearnerPresenceService _presence;
  late final NotificationLiveUpdates _liveNotifications;

  Future<void> _beatPresence() async {
    if (!mounted || !_isAppResumed || _presenceInFlight) return;
    _presenceInFlight = true;
    try {
      await _presence.heartbeat();
    } catch (_) {
      // Connection failure never prevents the learner from practicing.
    } finally {
      _presenceInFlight = false;
    }
  }

  Future<void> _closePresence() async {
    try {
      await _presence.close();
    } catch (_) {
      // Force-quit, offline use and revoked tokens expire on the server.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialTabApplied) return;
    _initialTabApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['initialTab'] == 1) {
      // Stage onboarding returns directly to verified stage categories.
      _selectedIndex = 1;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presence = ref.read(learnerPresenceServiceProvider);
    _liveNotifications = NotificationLiveUpdates(
      readToken: ref.read(apiClientProvider).readToken,
      onInboxChanged: () {
        if (!mounted || !_isAppResumed) return;
        ref.invalidate(notificationInboxProvider);
        ref.invalidate(notificationPageProvider);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_beatPresence());
        _liveNotifications.start();
      }
    });
    _notificationRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      // No background polling/heartbeat for a suspended mobile app.
      if (!mounted || !_isAppResumed) return;
      ref.invalidate(notificationInboxProvider);
      unawaited(_beatPresence());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (resumed && !_isAppResumed && mounted) {
      // Reconcile notifications, server-granted Premium and student stats
      // after external admin changes while the phone was in the background.
      ref.invalidate(notificationInboxProvider);
      ref.invalidate(studentPremiumProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(studentBadgesProvider);
      ref.invalidate(learningJourneyProvider);
    }
    _isAppResumed = resumed;
    if (resumed && mounted) {
      unawaited(_beatPresence());
      _liveNotifications.start();
    } else {
      _liveNotifications.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationRefresh?.cancel();
    _liveNotifications.stop();
    unawaited(_closePresence());
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