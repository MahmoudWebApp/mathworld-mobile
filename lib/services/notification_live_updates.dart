import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/constants.dart';

/// Foreground-only, JWT-authenticated notification hints using SSE.
/// No tokens in the URL, no third-party SDK, no notification contents in events.
/// If a connection fails, the existing minute-by-minute inbox refresh remains.
class NotificationLiveUpdates {
  NotificationLiveUpdates({
    required this.readToken,
    required this.onInboxChanged,
  });

  final Future<String?> Function() readToken;
  final void Function() onInboxChanged;

  HttpClient? _client;
  Timer? _retry;
  bool _active = false;
  bool _connecting = false;
  int _retrySeconds = 1;

  void start() {
    if (_active) return;
    _active = true;
    _retrySeconds = 1;
    unawaited(_connect());
  }

  void stop() {
    _active = false;
    _retry?.cancel();
    _retry = null;
    _client?.close(force: true);
    _client = null;
  }

  Future<void> _connect() async {
    if (!_active || _connecting) return;
    _connecting = true;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    _client = client;
    var connected = false;

    try {
      final token = await readToken();
      if (!_active || token == null || token.isEmpty) {
        stop();
        return;
      }
      final uri = Uri.parse('${ApiConstants.baseUrl}/notifications/stream');
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      final response = await request.close();
      if (!_active) return;

      // Expired/revoked tokens must never reconnect in a tight loop.
      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        stop();
        return;
      }
      if (response.statusCode != HttpStatus.ok ||
          !response.headers.contentType.toString().contains('text/event-stream')) {
        throw const HttpException('Notification stream unavailable');
      }

      connected = true;
      _retrySeconds = 1;
      onInboxChanged(); // Reconcile any notices sent before connection.
      await for (final line in response
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!_active) break;
        if (line.length > 256) throw const FormatException('Invalid SSE line');
        if (line.trim() == 'event: inbox') onInboxChanged();
      }
    } catch (_) {
      // Offline, prior backend version, proxy timeout and token expiry:
      // continue ordinary inbox polling, with bounded retries.
    } finally {
      client.close(force: true);
      if (identical(_client, client)) _client = null;
      _connecting = false;
      if (_active) {
        _retry?.cancel();
        _retry = Timer(Duration(seconds: _retrySeconds), () {
          if (_active) unawaited(_connect());
        });
        if (!connected) {
          _retrySeconds = (_retrySeconds * 2).clamp(1, 30).toInt();
        }
      }
    }
  }
}
