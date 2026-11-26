import 'dart:async';

import 'package:flutter/material.dart';
import '../../config/design_tokens.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/constants.dart';

/// Off by default until the official hosted widget and backend are configured.
/// No passwords, email addresses, session tokens or arbitrary URLs enter the WebView.
const authCaptchaEnabled = bool.fromEnvironment('MATHWORLD_CAPTCHA_ENABLED');

Future<String?> requestAuthCaptcha(BuildContext context, String action, bool ar) {
  if (!authCaptchaEnabled) return Future.value(null);
  if (action != 'login' && action != 'register') return Future.value(null);
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AuthCaptchaScreen(action: action, ar: ar),
  );
}

class _AuthCaptchaScreen extends StatefulWidget {
  const _AuthCaptchaScreen({required this.action, required this.ar});
  final String action;
  final bool ar;
  @override
  State<_AuthCaptchaScreen> createState() => _AuthCaptchaScreenState();
}

class _AuthCaptchaScreenState extends State<_AuthCaptchaScreen> {
  late final WebViewController _controller;
  late final Uri _url;
  bool _returned = false;
  bool _failed = false;
  bool _loading = true;
  Timer? _loadDeadline;

  void _startDeadline() {
    _loadDeadline?.cancel();
    _loadDeadline = Timer(const Duration(seconds: 30), () {
      if (mounted && !_returned && _loading) {
        setState(() { _failed = true; _loading = false; });
      }
    });
  }

  void _retry() {
    if (_returned) return;
    setState(() { _failed = false; _loading = true; });
    _startDeadline();
    _controller.loadRequest(_url);
  }

  void _cancel() {
    if (_returned) return;
    _returned = true;
    _loadDeadline?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _loadDeadline?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _url = Uri.parse('${AppConstants.officialWebsite}/captcha-challenge').replace(
      queryParameters: {'action': widget.action, 'lang': widget.ar ? 'ar' : 'en'},
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (request.isMainFrame) {
            return uri == _url ? NavigationDecision.navigate : NavigationDecision.prevent;
          }
          // Turnstile uses blank/srcdoc subframes during verification.
          // Never allow these or third-party domains as the top-level page.
          final allowedFrame = request.url == 'about:blank' ||
              request.url == 'about:srcdoc' ||
              (uri?.scheme == 'https' && uri?.host == 'challenges.cloudflare.com' && uri?.userInfo == '' && uri?.port == 443);
          return allowedFrame ? NavigationDecision.navigate : NavigationDecision.prevent;
        },
        onPageFinished: (url) {
          if (!mounted || _returned || url != _url.toString()) return;
          _loadDeadline?.cancel();
          if (_loading) setState(() => _loading = false);
        },
        onWebResourceError: (error) {
          if (mounted && !_returned && error.isForMainFrame == true) {
            _loadDeadline?.cancel();
            setState(() { _failed = true; _loading = false; });
          }
        },
      ))
      ..addJavaScriptChannel('MathWorldCaptcha', onMessageReceived: (message) async {
        if (_returned || !mounted || message.message.isEmpty || message.message.length > 2048) return;
        final current = await _controller.currentUrl();
        if (!mounted || _returned || current != _url.toString()) return;
        _returned = true;
        _loadDeadline?.cancel();
        Navigator.of(context).pop(message.message);
      })
      ..loadRequest(_url);
    _startDeadline();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440, maxHeight: 480),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.verified_user_outlined,
                color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(
                widget.ar ? 'التحقق الأمني' : 'Security verification',
                style: Theme.of(context).textTheme.titleMedium,
              )),
              IconButton(
                onPressed: _cancel,
                tooltip: widget.ar ? 'إلغاء' : 'Cancel',
                icon: const Icon(Icons.close_rounded),
              ),
            ]),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Flexible(
              child: SizedBox(
                height: 320,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_failed || _loading)
                      ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_loading)
                                  const CircularProgressIndicator(
                                    color: AppColors.brandPurple,
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  _failed
                                    ? (widget.ar ? 'تعذّر تحميل التحقق الأمني' : 'Could not load verification')
                                    : (widget.ar ? 'جارٍ تجهيز التحقق…' : 'Preparing verification…'),
                                  textAlign: TextAlign.center,
                                ),
                                if (_failed)
                                  TextButton(
                                    onPressed: _retry,
                                    child: Text(widget.ar ? 'إعادة المحاولة' : 'Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _loading ? null : _retry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(widget.ar ? 'إعادة تحميل التحقق' : 'Reload verification'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
