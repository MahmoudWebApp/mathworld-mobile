import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repositories_provider.dart';

/// The API verifies the current MathWorld identity from the session token.
/// Never infer a linked provider from whether a Google SDK session exists.
final googleLinkedProvider = FutureProvider.autoDispose<bool>((ref) async {
  final response = await ref.watch(apiClientProvider).get(
    '/auth/social/link-status',
  );
  final payload = response.data;
  if (payload is! Map) {
    throw const FormatException('Unexpected social link status response');
  }
  final raw = payload['Data'] ?? payload['data'] ?? payload;
  if (raw is! Map) {
    throw const FormatException('Unexpected social link status data');
  }
  return raw['GoogleLinked'] == true || raw['googleLinked'] == true;
});
