import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/services/premium_gift_service.dart';

void main() {
  group('PremiumGiftRedemption.fromJson', () {
    test('parses UTC expiry and grant days', () {
      final gift = PremiumGiftRedemption.fromJson({
        'GrantedDays': 365,
        'PremiumExpiresAtUtc': '2027-11-14T08:00:00Z',
      });
      expect(gift.grantedDays, 365);
      expect(gift.expiresAtUtc.isUtc, isTrue);
      expect(gift.expiresAtUtc.year, 2027);
    });

    test('rejects missing expiry instead of claiming success', () {
      expect(
        () => PremiumGiftRedemption.fromJson({'GrantedDays': 365}),
        throwsFormatException,
      );
    });

    test('rejects malformed days instead of showing an invented value', () {
      expect(
        () => PremiumGiftRedemption.fromJson({
          'GrantedDays': 'not-number',
          'PremiumExpiresAtUtc': '2027-11-14T08:00:00Z',
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
