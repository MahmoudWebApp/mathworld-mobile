import 'dart:math';

import '../core/network/api_client.dart';

/// A lightweight per-app-session signal used by the admin dashboard.
/// Online means the server received a heartbeat in the last five minutes.
/// We never send answers, location, IPs, a device fingerprint, or an exit guess.
class LearnerPresenceService {
  LearnerPresenceService(this._api) : sessionId = _newSessionId();

  final ApiClient _api;
  final String sessionId;

  static String _newSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> heartbeat() async {
    await _api.post(
      '/users/presence/heartbeat',
      data: {'SessionId': sessionId},
    );
  }

  Future<void> close() async {
    await _api.delete('/users/presence/sessions/$sessionId');
  }
}
