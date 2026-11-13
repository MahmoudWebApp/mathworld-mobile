import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_routes.dart';
import '../core/utils/error_message.dart';
import '../providers/auth_provider.dart';
import '../services/google_identity_service.dart';

/// Google sign-in is hidden unless the build has an explicit OAuth opt-in
/// and a nonempty server OAuth client ID. Existing password login is unchanged.
class SocialSignInButtons extends ConsumerStatefulWidget {
  const SocialSignInButtons({super.key});

  @override
  ConsumerState<SocialSignInButtons> createState() =>
      _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends ConsumerState<SocialSignInButtons> {
  bool _working = false;

  Future<void> _signIn() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
      if (!mounted) return;
      final user = ref.read(authProvider).user;
      final target = user?.role == 'Student' &&
              user?.currentStageId == null
          ? AppRoutes.learningStage
          : AppRoutes.home;
      Navigator.pushNamedAndRemoveUntil(context, target, (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleIdentityService.available) {
      return const SizedBox.shrink();
    }

    final isSubmitting = ref.watch(
      authProvider.select((state) => state.isSubmitting),
    );
    final busy = _working || isSubmitting;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        onPressed: busy ? null : _signIn,
        icon: busy
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.account_circle_outlined),
        label: Text('social_google'.tr()),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
