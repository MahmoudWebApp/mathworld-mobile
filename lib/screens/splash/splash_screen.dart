import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_states.dart';

/// Validates the stored session with the same unbranded content skeleton.
/// The native launch screen remains unchanged.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  void _navigate(AuthStatus status) {
    if (_hasNavigated || status == AuthStatus.checking) {
      return;
    }
    _hasNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        status == AuthStatus.authenticated
            ? AppRoutes.home
            : AppRoutes.login,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) => _navigate(next.status));
    final authState = ref.watch(authProvider);
    _navigate(authState.status);
    return const Scaffold(body: SafeArea(child: AppContentSkeleton(count:4)));
  }
}
