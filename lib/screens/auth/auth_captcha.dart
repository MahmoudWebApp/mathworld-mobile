import 'package:flutter/material.dart';
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
        onWebResourceError: (error) {
          if (mounted && error.isForMainFrame == true) setState(() => _failed = true);
        },
      ))
      ..addJavaScriptChannel('MathWorldCaptcha', onMessageReceived: (message) async {
        if (_returned || !mounted || message.message.isEmpty || message.message.length > 2048) return;
        final current = await _controller.currentUrl();
        if (!mounted || _returned || current != _url.toString()) return;
        _returned = true;
        Navigator.of(context).pop(message.message);
      })
      ..loadRequest(_url);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.ar ? 'التحقق الأمني' : 'Security verification'),
    content: SizedBox(
      width: 360,
      height: 240,
      child: _failed
          ? Center(child: TextButton(onPressed: () {
              setState(() => _failed = false);
              _controller.loadRequest(_url);
            }, child: Text(widget.ar ? 'إعادة المحاولة' : 'Retry')))
          : WebViewWidget(controller: _controller),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(widget.ar ? 'إلغاء' : 'Cancel'),
      ),
    ],
  );
}
