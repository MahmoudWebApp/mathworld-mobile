import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_envelope.dart';
import '../providers/auth_provider.dart';
import '../providers/repositories_provider.dart';

class EmailPreferencesDialog extends ConsumerStatefulWidget {
  const EmailPreferencesDialog({super.key, required this.userId});
  final int userId;
  @override
  ConsumerState<EmailPreferencesDialog> createState() => _EmailPreferencesDialogState();
}

class _EmailPreferencesDialogState extends ConsumerState<EmailPreferencesDialog> {
  static const _route = '/users/email-preferences';
  static const _keys = ['EmailLearningUpdates', 'EmailSubscriptionUpdates', 'EmailImportantAnnouncements'];
  Map<String, dynamic>? _value;
  bool _busy = true, _failed = false, _saved = false, _queued = false;
  String? _verificationError;
  bool get _sameUser => ref.read(authProvider).user?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted || !_sameUser) return;
    setState(() { _busy = true; _failed = false; _saved = false; _queued = false; _verificationError = null; });
    try {
      final response = await ref.read(apiClientProvider).get(_route);
      if (!mounted || !_sameUser) return;
      final data = ApiEnvelope.map(response.data);
      if (data['EmailVerified'] is! bool || data['OptionalDeliveryEnabled'] is! bool ||
          _keys.any((key) => data[key] is! bool) || !['ar','en'].contains(data['Locale'])) {
        throw const FormatException('Invalid preference response');
      }
      setState(() { _value = data; _busy = false; });
    } catch (_) {
      if (mounted) setState(() { _busy = false; _failed = true; });
    }
  }

  Future<void> _save() async {
    if (_busy || !_sameUser || _value == null) return;
    setState(() { _busy = true; _failed = false; _saved = false; });
    try {
      final response = await ref.read(apiClientProvider).put(_route, data: {
        for (final key in _keys) key: _value![key],
        'Locale': _value!['Locale'],
      });
      if (!mounted || !_sameUser) return;
      final data = ApiEnvelope.map(response.data);
      if (data['EmailVerified'] is! bool || data['OptionalDeliveryEnabled'] is! bool ||
          _keys.any((key) => data[key] is! bool) || !['ar','en'].contains(data['Locale'])) {
        throw const FormatException('Invalid preference response');
      }
      setState(() { _value = data; _busy = false; _saved = true; });
    } catch (_) {
      if (mounted) setState(() { _busy = false; _failed = true; });
    }
  }

  Future<void> _requestVerification(bool ar) async {
    if (_busy || !_sameUser || _value?['EmailVerified'] == true ||
        _value?['VerificationAvailable'] != true) return;
    setState(() { _busy = true; _queued = false; _failed = false; _saved = false; _verificationError = null; });
    try {
      final response = await ref.read(apiClientProvider).post('/auth/email-verification/request',
          data: {'Language': ar ? 'ar' : 'en'});
      if (!mounted || !_sameUser) return;
      final data = ApiEnvelope.map(response.data);
      if (data['AlreadyVerified'] == true) {
        await _load();
      } else if (data['Queued'] == true) {
        setState(() { _queued = true; _busy = false; });
      } else {
        throw const FormatException('Invalid verification response');
      }
    } catch (_) {
      if (mounted && _sameUser) {
        setState(() { _busy = false; _verificationError = ar
            ? 'تعذّر طلب رسالة التأكيد. انتظر قليلاً قبل إعادة المحاولة.'
            : 'Could not request verification. Wait before retrying.'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final current = ref.watch(authProvider.select((state) => state.user?.id));
    final value = current == widget.userId ? _value : null;
    final labels = ar ? ['الشهادات والإنجازات التعليمية','تحديثات الاشتراك','الإشعارات المهمة']
        : ['Certificates and learning achievements','Subscription updates','Important notices'];
    return AlertDialog(
      title: Text(ar ? 'تفضيلات البريد الإلكتروني' : 'Email preferences'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ar ? 'تظل إشعارات المنصة ورسائل الأمان مستقلة عن هذه الخيارات.' : 'In-app notifications and security messages are independent of these preferences.'),
        if (_busy) const LinearProgressIndicator(),
        if (value != null) ...[
          Text(value['EmailVerified'] == true
              ? (ar ? 'بريد الحساب مؤكّد.' : 'Account email verified.')
              : (ar ? 'يلزم تأكيد بريد الحساب أولاً.' : 'Verify your account email first.')),
          if (value['EmailVerified'] != true && value['VerificationAvailable'] == true)
            OutlinedButton(
              onPressed: _busy ? null : () => _requestVerification(ar),
              child: Text(ar ? 'إرسال رابط التأكيد' : 'Send verification link'),
            ),
          if (value['EmailVerified'] != true && value['VerificationAvailable'] != true)
            Text(ar ? 'إرسال رابط التأكيد غير متاح حالياً.' : 'Email verification is currently unavailable.'),
          if (value['OptionalDeliveryEnabled'] != true) Text(ar ? 'الإرسال الاختياري غير مفعّل حالياً.' : 'Optional delivery is currently disabled.'),
          for (var i = 0; i < _keys.length; i++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labels[i]),
              value: value[_keys[i]] == true,
              onChanged: _busy || (value['EmailVerified'] != true && value[_keys[i]] != true) ? null :
                  (checked) => setState(() { value[_keys[i]] = checked == true; _saved = false; }),
            ),
          Text(ar ? 'لغة الرسائل' : 'Email language'),
          DropdownButton<String>(
            value: value['Locale'] as String,
            items: const [DropdownMenuItem(value:'ar',child:Text('العربية')),DropdownMenuItem(value:'en',child:Text('English'))],
            onChanged: _busy ? null : (locale) => setState(() { value['Locale'] = locale; _saved = false; }),
          ),
        ],
        if (_failed) Text(ar ? 'تعذّر تحميل أو حفظ التفضيلات.' : 'Could not load or save preferences.',style:TextStyle(color:Theme.of(context).colorScheme.error)),
        if (_saved) Text(ar ? 'تم حفظ التفضيلات.' : 'Preferences saved.'),
        if (_queued) Text(ar
            ? 'أضيفت رسالة التأكيد إلى الطابور. افتح الرابط عند وصوله، ثم حدّث التفضيلات.'
            : 'Verification email queued. Open its link when received, then refresh preferences.'),
        if (_verificationError != null)
          Text(_verificationError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child:Text(ar?'إغلاق':'Close')),
        if (!_busy && current == widget.userId)
          TextButton(onPressed:_load,child:Text(value == null ? (ar?'إعادة المحاولة':'Retry') : (ar?'تحديث':'Refresh'))),
        if (value != null)
          FilledButton(onPressed:_busy?null:_save,child:Text(ar?'حفظ':'Save')),
      ],
    );
  }
}
