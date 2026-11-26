import 'package:easy_localization/easy_localization.dart';
import 'auth_captcha.dart';
import 'package:flutter/material.dart';
import '../../widgets/mathworld_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mobile_section.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/math_background.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/social_sign_in_buttons.dart';
import '../../core/utils/error_message.dart';

/// Displays the account registration form.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordSubmitting = false;
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordSubmitting || !_formKey.currentState!.validate() ||
        ref.read(authProvider).isSubmitting) return;
    setState(() => _passwordSubmitting = true);
    try {
      final captcha = await requestAuthCaptcha(context, 'register', context.locale.languageCode == 'ar');
      if (!mounted || (authCaptchaEnabled && captcha == null)) return;
      // Create the account first. Stage selection happens in the authenticated
      // onboarding screen, not in the registration form.
      await ref.read(authProvider.notifier).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        null,
        captchaToken: captcha,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      showMathWorldNotice(context,localizedErrorMessage(error),kind:MathWorldNoticeKind.error);
    } finally {
      if (mounted) setState(() => _passwordSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      authProvider.select((state) => state.isSubmitting),
    );
    return Scaffold(
      appBar: AppBar(),
      body: MathBackground(
        showSymbols: true,
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: MobilePanel(
                  gradient: Theme.of(context).brightness == Brightness.dark
                      ? AppGradients.darkHero : AppGradients.lightHero,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandMark(size: 72)),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'register_title'.tr(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'register_subtitle'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: InputDecoration(
                            labelText: 'full_name'.tr(),
                            prefixIcon:
                                const Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) => (value?.trim().length ?? 0) >= 2
                              ? null
                              : 'full_name_required'.tr(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'email'.tr(),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) {
                              return 'email_required'.tr();
                            }
                            if (!AppValidators.isValidEmail(input)) {
                              return 'invalid_email'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'password'.tr(),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) >= 6
                              ? null
                              : 'password_min_length'.tr(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'confirm_password'.tr(),
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == _passwordController.text
                                  ? null
                                  : 'passwords_not_match'.tr(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        PremiumButton(
                          onPressed: isLoading || _passwordSubmitting ? null : _submit,
                          label: context.locale.languageCode == 'ar' ? 'متابعة' : 'Continue',
                          leadingIcon: Icons.person_add_alt_1_rounded,
                          isLoading: _passwordSubmitting,
                          expand: true,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const SocialSignInButtons(),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  ),
                          child: Text('login_prompt'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
