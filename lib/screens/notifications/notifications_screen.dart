import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../models/student_notification.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

/// Full-screen private inbox with distinct loading/error/empty states.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _page = 1;
  bool _saving = false;

  Future<void> _markRead(StudentNotification item) async {
    if (_saving || item.isRead) return;
    setState(() => _saving = true);
    try {
      await ref.read(notificationsRepositoryProvider).markRead(item.id);
      ref.invalidate(notificationsPageProvider(_page));
      ref.invalidate(notificationsUnreadCountProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markAllRead() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      ref.invalidate(notificationsPageProvider);
      ref.invalidate(notificationsUnreadCountProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openAction(StudentNotification notification) {
    final action = notification.actionPath;
    if (action == null || !action.startsWith('/') ||
        action.startsWith('//')) return;
    // Only known internal actions are mapped to native Flutter routes.
    final problem = RegExp(r'^/problems/([0-9]+)$').firstMatch(action);
    if (problem != null) {
      Navigator.pushNamed(
        context, AppRoutes.problemDetails,
        arguments: int.parse(problem.group(1)!),
      );
    } else if (action.startsWith('/stages')) {
      Navigator.pushNamed(context, AppRoutes.learningStage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(notificationsPageProvider(_page));
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications_title'.tr()),
        actions: [
          pageState.maybeWhen(
            data: (data) => IconButton(
              tooltip: 'notifications_mark_all'.tr(),
              onPressed: _saving || data.unreadCount == 0 ? null : _markAllRead,
              icon: const Icon(Icons.done_all_rounded),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: MathBackground(
        child: SafeArea(
          child: pageState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppErrorView(
              message: localizedErrorMessage(error),
              onRetry: () => ref.invalidate(notificationsPageProvider(_page)),
            ),
            data: (data) {
              if (data.notifications.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppEmptyView(
                      icon: Icons.notifications_none_rounded,
                      title: 'notifications_empty_title'.tr(),
                      subtitle: 'notifications_empty_body'.tr(),
                      action: OutlinedButton.icon(
                        onPressed: () =>
                            ref.invalidate(notificationsPageProvider(_page)),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text('retry'.tr()),
                      ),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await ref.refresh(
                    notificationsPageProvider(_page).future,
                  ).then((_) {});
                  ref.invalidate(notificationsUnreadCountProvider);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'notifications_unread_count'.tr(
                        namedArgs: {'count': '${data.unreadCount}'},
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...data.notifications.map((notification) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    notification.isRead
                                        ? Icons.notifications_none_rounded
                                        : Icons.notifications_active_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: Theme.of(context)
                                          .textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (!notification.isRead)
                                    const Icon(Icons.circle, size: 9),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(notification.body),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                DateFormat.yMMMd(
                                  context.locale.languageCode,
                                ).add_jm().format(notification.createdAt.toLocal()),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.md,
                                children: [
                                  if (!notification.isRead)
                                    TextButton.icon(
                                      onPressed: _saving
                                          ? null
                                          : () => _markRead(notification),
                                      icon: const Icon(Icons.done_rounded),
                                      label: Text('notifications_mark_read'.tr()),
                                    ),
                                  if (notification.actionPath != null &&
                                      (notification.actionPath!.startsWith('/stages') ||
                                       RegExp(r'^/problems/[0-9]+$').hasMatch(
                                         notification.actionPath!)))
                                    TextButton.icon(
                                      onPressed: () {
                                        _markRead(notification);
                                        _openAction(notification);
                                      },
                                      icon: const Icon(Icons.open_in_new_rounded),
                                      label: Text('notifications_view_details'.tr()),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'previous'.tr(),
                          onPressed: _page > 1
                              ? () => setState(() => _page--)
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Text('$_page'),
                        IconButton(
                          tooltip: 'next'.tr(),
                          onPressed: data.hasMore
                              ? () => setState(() => _page++)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
