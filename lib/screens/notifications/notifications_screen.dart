import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_states.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = context.locale.languageCode == 'ar';
    final inboxState = ref.watch(notificationInboxProvider);
    final service = ref.read(notificationApiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'الإشعارات' : 'Notifications'),
        actions: [
          inboxState.maybeWhen(
            data: (data) => data.unreadCount > 0
                ? TextButton.icon(
                    onPressed: () async {
                      try {
                        await service.markAllRead();
                        ref.invalidate(notificationInboxProvider);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(localizedErrorMessage(e))),
                        );
                      }
                    },
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(ar ? 'قراءة الكل' : 'Read all'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: inboxState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: localizedErrorMessage(error),
          onRetry: () => ref.invalidate(notificationInboxProvider),
        ),
        data: (inbox) => RefreshIndicator(
          onRefresh: () => ref.refresh(notificationInboxProvider.future).then((_) {}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  ar ? 'إشعارات آخر 30 يوماً' : 'Notifications from the last 30 days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (inbox.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 48),
                        const SizedBox(height: 16),
                        Text(ar ? 'ما عندك إشعارات حالياً' : 'No notifications yet'),
                      ],
                    ),
                  ),
                )
              else
                for (final item in inbox.items)
                  Card(
                    color: item.isUnread
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : null,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: Icon(
                        item.isUnread ? Icons.notifications_active_outlined
                            : Icons.notifications_none_outlined,
                        color: item.isUnread ? AppColors.primary : null,
                      ),
                      title: Text(ar ? item.titleAr : item.titleEn,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          Text(ar ? item.bodyAr : item.bodyEn),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            MaterialLocalizations.of(context).formatMediumDate(
                              item.createdAtUtc.toLocal(),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (item.isUnread) {
                          try {
                            await service.markRead(item.id);
                            ref.invalidate(notificationInboxProvider);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(localizedErrorMessage(e))),
                            );
                            return;
                          }
                        }
                        // Subscription notices resolve to the main dashboard.
                        if (item.targetPath == '/dashboard' && context.mounted) {
                          Navigator.maybePop(context);
                        }
                      },
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  ar ? 'نهاية إشعارات آخر 30 يوماً' : 'End of 30-day notifications',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
