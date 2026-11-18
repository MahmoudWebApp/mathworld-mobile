import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/premium_checkout_service.dart';
import 'repositories_provider.dart';

final premiumCheckoutServiceProvider = Provider<PremiumCheckoutService>(
  (ref) => PremiumCheckoutService(ref.watch(apiClientProvider)),
);
