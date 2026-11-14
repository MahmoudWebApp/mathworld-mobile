import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/premium_gift_service.dart';
import 'repositories_provider.dart';

final premiumGiftServiceProvider = Provider<PremiumGiftService>(
  (ref) => PremiumGiftService(ref.watch(apiClientProvider)),
);
