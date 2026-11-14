import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_states.dart';

/// Complete thirty-day inbox with server-side pages. The home/bell provider
/// remains separate and is invalidated after every read so its dot stays fresh.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _page = 0;
  bool _markingAll = false;
  bool _markingNotice = false;

  void _refreshAfterRead() {
    ref.invalidate(notificationPageProvider(_page));
    ref.invalidate(notificationInboxProvider);
  }

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationApiServiceProvider).markAllRead();
      if (!mounted) return;
      _refreshAfterRead();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _readNotice(int id, bool isUnread, String? targetPath) async {
    if (_markingNotice) return;
    setState(() => _markingNotice = true);
    try {
      if (isUnread) {
        await ref.read(notificationApiServiceProvider).markRead(id);
        if (!mounted) return;
        _refreshAfterRead();
      }
      // Only this existing in-app destination is supported by the mobile
      // navigation tree; all other URL strings are ignored, never launched.
      if (targetPath == '/dashboard' && mounted) {
        Navigator.maybePop(context);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _markingNotice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final inboxState = ref.watch(notificationPageProvider(_page));

    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'كل الإشعارات' : 'All notifications'),
        actions: [
          inboxState.maybeWhen(
            data: (data) => data.unreadCount > 0
                ? TextButton.icon(
                    onPressed: _markingAll ? null : _markAllRead,
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(_markingAll
                        ? (ar ? 'جارٍ التحديث…' : 'Updating…')
                        : (ar ? 'قراءة الكل' : 'Read all')),
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
          onRetry: () => ref.invalidate(notificationPageProvider(_page)),
        ),
        data: (inbox) => RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(notificationPageProvider(_page).future).then((_) {});
            ref.invalidate(notificationInboxProvider);
          },
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
                  ar
                      ? 'إشعارات آخر 30 يوماً — من الأحدث إلى الأقدم'
                      : 'Last 30 days — newest first',
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
                        Text(ar ? 'لا توجد إشعارات بهذه الصفحة' : 'No notifications on this page'),
                      ],
                    ),
                  ),
                )
              else
                for (final item in inbox.items)
                  Card(
                    color: item.isUnread
                        ? Theme.of(context).colorScheme.primaryContainer
                            .withValues(alpha: 0.35)
                        : null,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      enabled: !_markingNotice,
                      leading: Icon(
                        item.isUnread
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_none_outlined,
                        color: item.isUnread ? AppColors.primary : null,
                      ),
                      title: Text(
                        ar ? item.titleAr : item.titleEn,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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
                      onTap: () => _readNotice(
                        item.id, item.isUnread, item.targetPath,
                      ),
                    ),
                  ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  ar
                      ? 'عرض ${inbox.items.isEmpty ? 0 : inbox.skip + 1}–${inbox.skip + inbox.items.length} من ${inbox.totalCount} إشعاراً · غير مقروء: ${inbox.unreadCount}'
                      : 'Showing ${inbox.items.isEmpty ? 0 : inbox.skip + 1}–${inbox.skip + inbox.items.length} of ${inbox.totalCount} · Unread: ${inbox.unreadCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _page > 0 && !_markingNotice
                        ? () => setState(() => _page--)
                        : null,
                    child: Text(ar ? 'السابق' : 'Previous'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: inbox.hasMore &&
                            !_markingNotice &&
                            (_page + 1) * notificationPageSize <= 10000
                        ? () => setState(() => _page++)
                        : null,
                    child: Text(ar ? 'التالي' : 'Next'),
                  ),
                ],
              ),
              if (!inbox.hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
