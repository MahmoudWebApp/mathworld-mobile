import 'package:flutter/material.dart';

/// Stores global navigation keys used for centralized session redirects.
class AppNavigator {
  const AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
}
