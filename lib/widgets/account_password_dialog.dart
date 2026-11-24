import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/error_message.dart';
import '../providers/auth_provider.dart';

bool validNewAccountPassword(String password, String confirmation) =>
    password == confirmation && password.length >= 12 &&
    password.trim().isNotEmpty && utf8.encode(password).length <= 72 &&
    !password.runes.any((r) => r < 32 || (r >= 127 && r <= 159));

class AccountPasswordDialog extends ConsumerStatefulWidget {
  const AccountPasswordDialog({super.key});
  @override
  ConsumerState<AccountPasswordDialog> createState() => _AccountPasswordDialogState();
}

class _AccountPasswordDialogState extends ConsumerState<AccountPasswordDialog> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose(); _password.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit(bool ar) async {
    if (_busy) return;
    if (_current.text.isEmpty || !validNewAccountPassword(_password.text, _confirm.text)) {
      setState(() => _error = ar
          ? 'تأكد من كلمة المرور الحالية وتطابق الكلمتين الجديدتين (12 حرفاً على الأقل و72 بايت كحد أقصى).'
          : 'Enter your current password and matching new passwords (12 characters minimum, 72 UTF-8 bytes maximum).');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).changePassword(_current.text, _password.text, _confirm.text);
      if (!mounted) return;
      _current.clear(); _password.clear(); _confirm.clear();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() { _busy = false; _error = localizedErrorMessage(error); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    Widget field(TextEditingController controller, String label, String autofill) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller, enabled: !_busy, obscureText: true,
        autocorrect: false, enableSuggestions: false, maxLength: 128,
        autofillHints: [autofill], decoration: InputDecoration(labelText: label, counterText: ''),
      ),
    );
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(ar ? 'تغيير كلمة المرور' : 'Change password'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(ar ? 'لحسابات كلمة المرور المحلية. سيتم تسجيل خروج الأجهزة بعد النجاح. حسابات Google فقط تدير كلمة المرور عبر Google.'
              : 'For local passwords. Devices sign out after success. Google-only accounts manage passwords through Google.'),
          field(_current, ar ? 'الحالية' : 'Current password', AutofillHints.password),
          field(_password, ar ? 'الجديدة' : 'New password', AutofillHints.newPassword),
          field(_confirm, ar ? 'تأكيد الجديدة' : 'Confirm password', AutofillHints.newPassword),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ])),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: Text(ar ? 'إلغاء' : 'Cancel')),
          FilledButton(onPressed: _busy ? null : () => _submit(ar), child: _busy
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(ar ? 'تغيير' : 'Change')),
        ],
      ),
    );
  }
}
