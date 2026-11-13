/// Backend-enforced quota for first-ever attempts in a single stage.
class StageDailyQuota {
  final int stageId;
  final String nameAr;
  final String nameEn;
  final int limit;
  final int used;
  final int? remaining;
  final bool unlimited;
  final String subscriptionType;
  final DateTime? dayUtc;
  final DateTime? resetsAtUtc;

  const StageDailyQuota({
    required this.stageId,
    required this.nameAr,
    required this.nameEn,
    required this.limit,
    required this.used,
    required this.remaining,
    required this.unlimited,
    required this.subscriptionType,
    required this.dayUtc,
    required this.resetsAtUtc,
  });

  factory StageDailyQuota.fromJson(Map<String, dynamic> json) {
    int integer(String key, String camel) {
      final value = json[key] ?? json[camel];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final unlimited = json['Unlimited'] == true || json['unlimited'] == true;
    final remaining = json['Remaining'] ?? json['remaining'];
    return StageDailyQuota(
      stageId: integer('StageId', 'stageId'),
      nameAr: (json['NameAr'] ?? json['nameAr'] ?? '').toString(),
      nameEn: (json['NameEn'] ?? json['nameEn'] ?? '').toString(),
      limit: integer('Limit', 'limit'),
      used: integer('Used', 'used'),
      remaining: unlimited ? null : remaining is num
          ? remaining.toInt()
          : int.tryParse(remaining?.toString() ?? ''),
      unlimited: unlimited,
      subscriptionType:
          (json['SubscriptionType'] ?? json['subscriptionType'] ?? 'Free').toString(),
      dayUtc: DateTime.tryParse(
        (json['DayUtc'] ?? json['dayUtc'] ?? '').toString(),
      ),
      resetsAtUtc: DateTime.tryParse(
        (json['ResetsAtUtc'] ?? json['resetsAtUtc'] ?? '').toString(),
      ),
    );
  }

  bool get exhausted => !unlimited && (remaining ?? 0) <= 0;
  String stageName(String language) => language == 'en' ? nameEn : nameAr;
}
