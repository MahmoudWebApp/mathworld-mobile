import '../core/network/api_client.dart';
import '../core/network/api_envelope.dart';

/// A price preview is not a payment, reservation, or Premium grant.
class PremiumDiscountQuote {
  const PremiumDiscountQuote({
    required this.subtotalUsd,
    required this.discountUsd,
    required this.totalUsd,
    required this.endsAtUtc,
  });

  final double subtotalUsd;
  final double discountUsd;
  final double totalUsd;
  final DateTime endsAtUtc;

  factory PremiumDiscountQuote.fromJson(Map<String, dynamic> json) {
    final endsAt = DateTime.tryParse(json['EndsAtUtc']?.toString() ?? '');
    if (endsAt == null) {
      throw const FormatException('Invalid discount end date');
    }
    return PremiumDiscountQuote(
      subtotalUsd: (json['SubtotalUsd'] as num).toDouble(),
      discountUsd: (json['DiscountUsd'] as num).toDouble(),
      totalUsd: (json['TotalUsd'] as num).toDouble(),
      endsAtUtc: endsAt,
    );
  }
}

class PremiumCheckoutOrder {
  const PremiumCheckoutOrder({
    required this.id,
    required this.reference,
    required this.status,
    required this.subtotalUsd,
    required this.discountUsd,
    required this.totalUsd,
    required this.createdAtUtc,
  });

  final int id;
  final String reference;
  final String status;
  final double subtotalUsd;
  final double discountUsd;
  final double totalUsd;
  final DateTime createdAtUtc;

  factory PremiumCheckoutOrder.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['CreatedAtUtc']?.toString() ?? '');
    if (createdAt == null) {
      throw const FormatException('Invalid checkout date');
    }
    return PremiumCheckoutOrder(
      id: (json['Id'] as num).toInt(),
      reference: json['OrderReference']?.toString() ?? '',
      status: json['Status']?.toString() ?? '',
      subtotalUsd: (json['SubtotalUsd'] as num).toDouble(),
      discountUsd: (json['DiscountUsd'] as num).toDouble(),
      totalUsd: (json['TotalUsd'] as num).toDouble(),
      createdAtUtc: createdAt,
    );
  }
}

class PremiumCheckoutHistory {
  const PremiumCheckoutHistory({
    required this.orders,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<PremiumCheckoutOrder> orders;
  final int total;
  final int page;
  final int pageSize;

  factory PremiumCheckoutHistory.fromJson(Map<String, dynamic> json) {
    final rows = json['Orders'];
    if (rows is! List) {
      throw const FormatException('Invalid Premium order list');
    }
    return PremiumCheckoutHistory(
      orders: rows
          .map((row) => PremiumCheckoutOrder.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList(growable: false),
      total: (json['Total'] as num).toInt(),
      page: (json['Page'] as num).toInt(),
      pageSize: (json['PageSize'] as num).toInt(),
    );
  }
}

/// Uses existing authenticated HTTP client. No client-controlled payment state.
class PremiumCheckoutService {
  const PremiumCheckoutService(this._api);
  final ApiClient _api;

  Future<PremiumDiscountQuote> quote(String code) async {
    final value = code.trim();
    if (value.isEmpty || value.length > 60) {
      throw const FormatException('Invalid discount code');
    }
    final response = await _api.post(
      '/users/premium-discounts/quote',
      data: {'Code': value},
    );
    return PremiumDiscountQuote.fromJson(ApiEnvelope.map(response.data));
  }

  Future<PremiumCheckoutHistory> history({int page = 1}) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    final response = await _api.get(
      '/users/premium-checkout/orders',
      queryParameters: {'page': page, 'pageSize': 10},
    );
    return PremiumCheckoutHistory.fromJson(ApiEnvelope.map(response.data));
  }

  Future<PremiumCheckoutOrder> prepare({String? discountCode}) async {
    final response = await _api.post(
      '/users/premium-checkout/orders',
      data: {'DiscountCode': discountCode?.trim()},
    );
    return PremiumCheckoutOrder.fromJson(ApiEnvelope.map(response.data));
  }

  Future<void> cancelDraft(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    await _api.post('/users/premium-checkout/orders/$id/cancel');
  }
}
