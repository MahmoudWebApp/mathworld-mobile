import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/constants.dart';

/// Obtains a Google ID token; MathWorld backend must verify the token
/// audience against the same Google Web/server OAuth client ID.
/// No Google password or provider token is persisted by this class.
class GoogleIdentityService {
  GoogleIdentityService._();

  static final GoogleSignIn _google = GoogleSignIn.instance;
  static Future<void>? _initialization;

  static bool get available => SocialAuthConfig.googleAvailable;

  static Future<String> requestIdToken() async {
    if (!available) {
      throw StateError('Google sign-in is not configured for this build.');
    }

    _initialization ??= _google.initialize(
      serverClientId: SocialAuthConfig.googleServerClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS &&
              SocialAuthConfig.googleIosClientId.isNotEmpty
          ? SocialAuthConfig.googleIosClientId
          : null,
    );
    await _initialization;

    if (!_google.supportsAuthenticate()) {
      throw UnsupportedError(
        'This Google sign-in method requires Android or iOS.',
      );
    }

    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return an identity token.');
    }
    return idToken;
  }
}
