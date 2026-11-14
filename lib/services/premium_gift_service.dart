import '../core/network/api_client.dart';
import '../core/network/api_envelope.dart';

/// Single-use, administrator-issued gift. The payment checkout is not involved.
class PremiumGiftRedemption {
  const PremiumGiftRedemption({
    required this.grantedDays,
    required this.expiresAtUtc,
  });

  final int grantedDays;
  final DateTime expiresAtUtc;

  factory PremiumGiftRedemption.fromJson(Map<String, dynamic> json) {
    final expiresAt = DateTime.tryParse(
      json['PremiumExpiresAtUtc']?.toString() ?? '',
    );
    if (expiresAt == null) {
      throw const FormatException('Invalid gift subscription expiry');
    }
    return PremiumGiftRedemption(
      grantedDays: (json['GrantedDays'] as num).toInt(),
      expiresAtUtc: expiresAt,
    );
  }
}

class PremiumGiftService {
  const PremiumGiftService(this._client);
  final ApiClient _client;

  Future<PremiumGiftRedemption> redeem(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      throw const FormatException('Invalid gift code');
    }
    final response = await _client.post(
      '/users/premium-codes/redeem',
      data: {'Code': trimmed},
    );
    return PremiumGiftRedemption.fromJson(ApiEnvelope.map(response.data));
  }
}
