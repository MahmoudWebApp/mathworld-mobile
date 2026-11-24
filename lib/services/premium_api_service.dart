import '../core/network/api_client.dart';

/// Server-controlled student entitlements. UI flags are not authorization.
class StudentEntitlement {
  const StudentEntitlement({
    required this.subscriptionType,
    required this.isPremium,
    required this.dailyNewProblemsLimit,
    required this.canRevealSolutionBeforeAnswer,
    required this.canExportAnalytics,
    required this.adsEligible,
    this.premiumExpiresAtUtc,
  });

  final String subscriptionType;
  final bool isPremium;
  final DateTime? premiumExpiresAtUtc;
  final int? dailyNewProblemsLimit;
  final bool canRevealSolutionBeforeAnswer;
  final bool canExportAnalytics;
  final bool adsEligible;

  factory StudentEntitlement.fromJson(Map<String, dynamic> json) =>
      StudentEntitlement(
        subscriptionType: json['SubscriptionType'] as String? ?? 'Free',
        isPremium: json['IsPremium'] == true,
        premiumExpiresAtUtc: DateTime.tryParse(
          json['PremiumExpiresAtUtc'] as String? ?? '',
        ),
        dailyNewProblemsLimit: json['DailyNewProblemsLimit'] as int?,
        canRevealSolutionBeforeAnswer:
            json['CanRevealSolutionBeforeAnswer'] == true,
        canExportAnalytics: json['CanExportAnalytics'] == true,
        adsEligible: json['AdsEligible'] == true,
      );
}

class ProblemHints {
  final int problemId, revealedCount;
  final bool available;
  final List<String> hints;
  const ProblemHints({required this.problemId,required this.revealedCount,required this.available,required this.hints});
  factory ProblemHints.fromJson(Map<String,dynamic> json)=>ProblemHints(
    problemId:json['ProblemId'] as int,
    revealedCount:json['RevealedCount'] as int? ?? 0,
    available:json['Available']==true,
    hints:(json['Hints'] as List? ?? []).whereType<Map>().map((h)=>h['Text'].toString()).toList(),
  );
}
class PremiumSolution {
  const PremiumSolution({
    required this.problemId,
    this.correctOptionId,
    this.detailedSolution,
    this.youtubeSolutionUrl,
  });

  final int problemId;
  final int? correctOptionId;
  final String? detailedSolution;
  final String? youtubeSolutionUrl;

  factory PremiumSolution.fromJson(Map<String, dynamic> json) =>
      PremiumSolution(
        problemId: json['ProblemId'] as int,
        correctOptionId: json['CorrectOptionId'] as int?,
        detailedSolution: json['DetailedSolution'] as String?,
        youtubeSolutionUrl: json['YoutubeSolutionUrl'] as String?,
      );
}

/// Uses the existing Dio client, including secure JWT and locale interceptors.
class PremiumApiService {
  const PremiumApiService(this._api);

  final ApiClient _api;

  Future<StudentEntitlement> getEntitlement() async {
    final response = await _api.get('/users/subscription');
    final envelope = Map<String, dynamic>.from(response.data as Map);
    return StudentEntitlement.fromJson(
      Map<String, dynamic>.from(envelope['Data'] as Map),
    );
  }

  Future<PremiumSolution> getSolution(int problemId) async {
    if (problemId <= 0) {
      throw ArgumentError.value(problemId, 'problemId', 'Must be positive');
    }
    final response = await _api.get(
      '/problems/$problemId/premium-solution',
    );
    final envelope = Map<String, dynamic>.from(response.data as Map);
    return PremiumSolution.fromJson(
      Map<String, dynamic>.from(envelope['Data'] as Map),
    );
  }

  Future<ProblemHints> getHints(int problemId,{int? level}) async {
    if(problemId<=0 || (level!=null && level!=1 && level!=2))throw ArgumentError('Invalid hint request');
    final response=level==null
        ?await _api.get('/problems/$problemId/hints')
        :await _api.post('/problems/$problemId/hints',data:{'Level':level});
    return ProblemHints.fromJson(Map<String,dynamic>.from(response.data as Map));
  }

  Future<Map<String, bool>> getLaunchFeatures() async {
    final response = await _api.get('/config/features');
    final envelope = Map<String, dynamic>.from(response.data as Map);
    final data = Map<String, dynamic>.from(envelope['Data'] as Map);
    return data.map((key, value) => MapEntry(key, value == true));
  }
}
