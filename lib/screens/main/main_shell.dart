import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../dashboard/favorites_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../stages/stages_screen.dart';

/// Hosts the primary application sections and the floating navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    HomeScreen(onOpenStages: () => setState(() => _selectedIndex = 1)),
    const StagesScreen(embedded: true),
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
        extendBody: true,
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : Colors.white)
                      .withValues(alpha: isDark ? 0.84 : 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.95),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.30 : 0.08,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
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
                      icon: const Icon(Icons.school_outlined),
                      selectedIcon: const Icon(Icons.school_rounded),
                      label: 'stages'.tr(),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.favorite_border_rounded),
                      selectedIcon: const Icon(Icons.favorite_rounded),
                      label: 'favorites'.tr(),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.tune_rounded),
                      selectedIcon: const Icon(Icons.tune_rounded),
                      label: 'settings'.tr(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
