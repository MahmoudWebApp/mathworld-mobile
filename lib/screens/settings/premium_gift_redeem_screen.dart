import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/premium_analytics_provider.dart';
import '../../providers/premium_gift_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../services/premium_gift_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

class PremiumGiftRedeemScreen extends ConsumerStatefulWidget {
  const PremiumGiftRedeemScreen({super.key});

  @override
  ConsumerState<PremiumGiftRedeemScreen> createState() =>
      _PremiumGiftRedeemScreenState();
}

class _PremiumGiftRedeemScreenState
    extends ConsumerState<PremiumGiftRedeemScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;
  PremiumGiftRedemption? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    if (_submitting) return;
    final code = _controller.text.trim();
    final ar = context.locale.languageCode == 'ar';
    if (code.isEmpty || code.length > 100) {
      setState(() => _error = ar ? 'أدخل كود هدية صحيحاً.'
          : 'Enter a valid gift code.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref.read(premiumGiftServiceProvider).redeem(code);
      if (!mounted) return;
      // Refresh all subscription and inbox surfaces after server redemption.
      ref.invalidate(studentPremiumProvider);
      ref.invalidate(stageCategoryAccessProvider);
      ref.invalidate(premiumAnalyticsProvider);
      ref.invalidate(notificationInboxProvider);
      ref.invalidate(dashboardProvider);
      _controller.clear();
      setState(() {
        _result = result;
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      final localized = localizedErrorMessage(error);
      setState(() {
        _submitting = false;
        _error = localized.isNotEmpty ? localized : (ar
            ? 'الكود غير متاح أو مستخدم أو منتهي الصلاحية.'
            : 'Code unavailable, already used or expired.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'تفعيل هدية Premium' : 'Redeem Premium gift')),
      body: MathBackground(
        showSymbols: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Icon(Icons.card_giftcard_rounded,
                        color: AppColors.primary, size: 50),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    ar ? 'عندك كود هدية؟' : 'Have a gift code?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    ar
                        ? 'أدخل الكود المقدم من إدارة MathWorld لتفعيل اشتراك Premium.'
                        : 'Enter the code supplied by MathWorld to activate Premium.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _controller,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.characters,
                    textDirection: TextDirection.ltr,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: ar ? 'كود الهدية' : 'Gift code',
                      hintText: 'MW-XXXXXXXXXXXX-XXXXXXXXXXXX-XXXXXXXXXXXX',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _redeem,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: Text(_submitting
                        ? (ar ? 'جارٍ التفعيل…' : 'Activating…')
                        : (ar ? 'تفعيل Premium' : 'Activate Premium')),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_error!, style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    )),
                  ],
                  if (_result != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 34),
                    Text(
                      ar ? 'تم تفعيل Premium بنجاح!' : 'Premium activated!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      ar
                          ? 'مدة الهدية: ${_result!.grantedDays} يوماً'
                          : 'Gift duration: ${_result!.grantedDays} days',
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${ar ? 'ينتهي' : 'Expires'}: '
                      '${MaterialLocalizations.of(context).formatMediumDate(_result!.expiresAtUtc.toLocal())}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              ar
                  ? 'أكواد الهدايا للاستخدام مرة واحدة، ولا تتطلب وسيلة دفع.'
                  : 'Gift codes work once and require no payment information.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
