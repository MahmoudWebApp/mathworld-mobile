import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

/// Loads all categories with localized cache fallback.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  return ref.watch(contentRepositoryProvider).getCategories(languageCode);
});

/// Filters categories for a stage while preserving loading and error states.
final stageCategoriesProvider = FutureProvider.family<List<Category>, int>(
  (ref, stageId) async {
    final categories = await ref.watch(categoriesProvider.future);
    return categories.where((item) => item.stageId == stageId).toList();
  },
);
