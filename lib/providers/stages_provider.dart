import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stage.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

/// Loads educational stages with localized cache fallback.
final stagesProvider = FutureProvider<List<Stage>>((ref) async {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  return ref.watch(contentRepositoryProvider).getStages(languageCode);
});
