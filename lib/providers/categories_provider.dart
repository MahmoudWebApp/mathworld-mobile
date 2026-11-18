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
    // Keep Free category unlocks aligned with the backend's Order + Id
    // ordering, including when older API/cache responses have ties.
    final stageCategories =
        categories.where((item) => item.stageId == stageId).toList();
    stageCategories.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
    return stageCategories;
  },
);
