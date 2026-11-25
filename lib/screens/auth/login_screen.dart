import 'package:easy_localization/easy_localization.dart';
import 'auth_captcha.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/math_background.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/social_sign_in_buttons.dart';

/// Displays the email and password authentication form.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _passwordSubmitting = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordSubmitting || ref.read(authProvider).isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _passwordSubmitting = true);
    try {
      final captcha = await requestAuthCaptcha(context, 'login', context.locale.languageCode == 'ar');
      if (!mounted || (authCaptchaEnabled && captcha == null)) return;
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
            captchaToken: captcha,
          );
      if (!mounted) {
        return;
      }
      final user = ref.read(authProvider).user;
      final destination = user?.role == 'Student' &&
              user?.currentStageId == null
          ? AppRoutes.learningStage
          : AppRoutes.home;
      Navigator.pushNamedAndRemoveUntil(context, destination, (_) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _passwordSubmitting = false);
    }
  }

  Future<void> _recoverPassword() async {
    final ar = context.locale.languageCode == 'ar';
    // Only the official website handles recovery secrets; no arbitrary links,
    // WebView, browser credentials or reset token are passed from the app.
    try {
      if (await launchUrl(AppConstants.passwordRecoveryUrl(ar ? 'ar' : 'en'),
          mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
      ar ? 'تعذّر فتح صفحة الاستعادة.' : 'Could not open the recovery page.',
    )));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      authProvider.select((state) => state.isSubmitting),
    );
    return Scaffold(
      body: MathBackground(
        showSymbols: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: GlassCard(
                  blur: 18,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandMark(size: 82)),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'login_title'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'login_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xl),
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
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
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
                          validator: (value) => value?.isNotEmpty == true
                              ? null
                              : 'password_required'.tr(),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: isLoading ? null : _recoverPassword,
                            child: Text(context.locale.languageCode == 'ar'
                                ? 'نسيت كلمة المرور؟' : 'Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PremiumButton(
                          onPressed: isLoading ? null : _submit,
                          label: 'login'.tr(),
                          leadingIcon: Icons.login_rounded,
                          // A Google sign-in disables this button but must not animate it.
                          isLoading: _passwordSubmitting,
                          expand: true,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const SocialSignInButtons(),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.register,
                                  ),
                          child: Text('create_account_prompt'.tr()),
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
