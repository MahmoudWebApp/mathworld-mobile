import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/math_background.dart';

/// Validate the stored session with the branded launch experience.
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
    return const Scaffold(body: MathBackground(child: SafeArea(child: Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: 110),
        SizedBox(height: 18),
        Text('MathWorld',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:Color(0xFF7937C3))),
        SizedBox(height: 28),
        AppInlineLoader(size: 32),
      ],
    )))));
  }
}
