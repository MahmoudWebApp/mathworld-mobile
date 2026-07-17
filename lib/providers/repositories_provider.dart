import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/content_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/problems_repository.dart';
import '../services/api_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiService());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(ref.watch(apiClientProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);

final problemsRepositoryProvider = Provider<ProblemsRepository>(
  (ref) => ProblemsRepository(ref.watch(apiClientProvider)),
);
