import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../widgets/mathworld_feedback.dart';
import '../../widgets/mathworld_pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/premium_checkout_provider.dart';
import '../../services/premium_checkout_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

/// Price previews and order history never activate Premium or take payment.
class PremiumCheckoutScreen extends ConsumerStatefulWidget {
  const PremiumCheckoutScreen({super.key});

  @override
  ConsumerState<PremiumCheckoutScreen> createState() => _PremiumCheckoutScreenState();
}

class _PremiumCheckoutScreenState extends ConsumerState<PremiumCheckoutScreen> {
  final _code = TextEditingController();
  PremiumDiscountQuote? _quote;
  PremiumCheckoutHistory? _history;
  String? _quoteError;
  String? _historyError;
  bool _checking = false;
  bool _loading = false;
  bool _cancelling = false;
  int _page = 1;
  int _quoteGeneration = 0;
  int _historyGeneration = 0;

  bool get _ar => context.locale.languageCode == 'ar';
  String _usd(double number) => 'USD ' + number.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadOrders);
  }

  @override
  void dispose() {
    _quoteGeneration++;
    _historyGeneration++;
    _code.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final code = _code.text.trim();
    if (code.isEmpty || _checking) return;
    final token = ++_quoteGeneration;
    setState(() {
      _checking = true;
      _quote = null;
      _quoteError = null;
    });
    try {
      final result = await ref.read(premiumCheckoutServiceProvider).quote(code);
      if (!mounted || token != _quoteGeneration) return;
      setState(() => _quote = result);
    } catch (error) {
      if (!mounted || token != _quoteGeneration) return;
      setState(() => _quoteError = localizedErrorMessage(error));
    } finally {
      if (mounted && token == _quoteGeneration) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    final token = ++_historyGeneration;
    setState(() {
      _loading = true;
      _historyError = null;
    });
    try {
      final result = await ref.read(premiumCheckoutServiceProvider).history(page: _page);
      if (!mounted || token != _historyGeneration) return;
      setState(() => _history = result);
    } catch (error) {
      if (!mounted || token != _historyGeneration) return;
      setState(() {
        _history = null;
        _historyError = localizedErrorMessage(error);
      });
    } finally {
      if (mounted && token == _historyGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _cancel(PremiumCheckoutOrder order) async {
    if (_cancelling) return;
    final ar = _ar;
    final confirm=await showMathWorldConfirmation(context,
      title:ar?'إلغاء طلب الاشتراك؟':'Cancel checkout order?',
      message:ar?'يمكن إلغاء الطلب المبدئي غير المدفوع فقط.':'Only unpaid checkout drafts can be cancelled.',
      cancel:ar?'رجوع':'Back',confirm:ar?'تأكيد':'Confirm');
    if (confirm != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(premiumCheckoutServiceProvider).cancelDraft(order.id);
      if (!mounted) return;
      await _loadOrders();
    } catch (error) {
      if (!mounted) return;
      showMathWorldNotice(context,localizedErrorMessage(error,kind:MathWorldNoticeKind.error),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _status(String status) {
    switch (status) {
      case 'Pending': return _ar ? 'بانتظار الدفع' : 'Pending payment';
      case 'Paid': return _ar ? 'مدفوع' : 'Paid';
      case 'Failed': return _ar ? 'فشل' : 'Failed';
      case 'Cancelled': return _ar ? 'ملغى' : 'Cancelled';
      case 'Refunded': return _ar ? 'مسترد' : 'Refunded';
      default: return status;
    }
  }

  Widget _price(String title, double amount, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title),
      Text(_usd(amount),
        style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final ar = _ar;
    final pages = _history == null ? 1 : (_history!.total / 10).ceil().clamp(1, 1000000);
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'Premium والخصومات' : 'Premium & discounts')),
      body: MathBackground(
        showSymbols: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Center(child: Icon(Icons.workspace_premium_rounded,
                size: 40, color: AppColors.primary)),
              const SizedBox(height: 12),
              Text(ar ? 'الاشتراك السنوي: 5 دولارات' : 'Annual Premium: USD 5',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(ar
                  ? 'المجاني: فئتان بكل مرحلة وحل غير محدود. Premium: جميع الفئات والحلول المسبقة والإحصائيات.'
                  : 'Free: two categories per stage, unlimited practice. Premium: every category, solution previews and analytics.'),
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                maxLength: 60,
                textDirection: ui.TextDirection.ltr,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) {
                  _quoteGeneration++;
                  setState(() {
                    _checking = false;
                    _quote = null;
                    _quoteError = null;
                  });
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: ar ? 'كود خصم' : 'Discount code',
                  hintText: 'MD-XXXXXXXXXXXX-XXXXXXXXXXXX-XXXXXXXXXXXX',
                ),
              ),
              FilledButton(
                onPressed: _checking || _code.text.trim().isEmpty ? null : _preview,
                child: Text(_checking ? (ar ? 'جارٍ التحقق…' : 'Checking…')
                    : (ar ? 'معاينة الخصم' : 'Preview discount')),
              ),
              if (_quoteError != null)
                Text(_quoteError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_quote != null) ...[
                const SizedBox(height: 16),
                _price(ar ? 'السعر الأصلي' : 'Subtotal', _quote!.subtotalUsd),
                _price(ar ? 'الخصم' : 'Discount', -_quote!.discountUsd),
                const Divider(),
                _price(ar ? 'بعد الخصم' : 'Total', _quote!.totalUsd, bold: true),
                Text((ar ? 'ينتهي: ' : 'Expires: ') +
                    MaterialLocalizations.of(context).formatMediumDate(_quote!.endsAtUtc.toLocal())),
              ],
              const SizedBox(height: 14),
              Text(ar
                  ? 'هذه معاينة فقط: الدفع الإلكتروني غير مفعّل، والسعر غير محجوز ولا يفعّل Premium.'
                  : 'Preview only: payment is not enabled; the price is not reserved and Premium is not activated.',
                  style: Theme.of(context).textTheme.bodySmall),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.premiumGiftRedeem),
                icon: const Icon(Icons.card_giftcard_outlined),
                label: Text(ar ? 'تفعيل كود هدية' : 'Redeem a Premium gift'),
              ),
            ])),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(ar ? 'سجل الطلبات' : 'Order history',
                    style: Theme.of(context).textTheme.titleLarge)),
                IconButton(onPressed: _loading ? null : _loadOrders,
                    tooltip: ar ? 'تحديث' : 'Refresh',
                    icon: const Icon(Icons.refresh_rounded)),
              ]),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_historyError != null)
                Text(_historyError!, style: TextStyle(color: Theme.of(context).colorScheme.error))
              else if (_history?.orders.isEmpty ?? true)
                Text(ar ? 'لا توجد طلبات حتى الآن.' : 'No orders yet.')
              else ..._history!.orders.map((order) => Column(children: [
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(order.reference, textDirection: ui.TextDirection.ltr),
                  subtitle: Text(_status(order.status) + ' · ' +
                      MaterialLocalizations.of(context).formatMediumDate(order.createdAtUtc.toLocal()) +
                      '\n' + (ar ? 'الخصم: ' : 'Discount: ') + _usd(order.discountUsd)),
                  trailing: Text(_usd(order.totalUsd),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (order.status == 'Pending')
                  Align(alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _cancelling ? null : () => _cancel(order),
                      child: Text(ar ? 'إلغاء الطلب' : 'Cancel draft'),
                    )),
              ])),
              MathWorldPagination(page:_page,pageCount:pages,arabic:ar,disabled:_loading||_history==null,onChanged:(p){setState(()=>_page=p);_loadOrders();}),

            ])),
          ],
        ),
      ),
    );
  }
}
