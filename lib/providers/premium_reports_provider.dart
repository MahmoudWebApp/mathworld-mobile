import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/premium_progress_report.dart';
import '../repositories/premium_reports_repository.dart';
import 'repositories_provider.dart';

final premiumReportsRepositoryProvider = Provider<PremiumReportsRepository>(
  (ref) => PremiumReportsRepository(ref.watch(apiClientProvider)),
);

final premiumProgressReportProvider =
    FutureProvider.autoDispose.family<PremiumProgressReport, int>((ref, stageId) =>
      ref.watch(premiumReportsRepositoryProvider).getReport(stageId: stageId));
