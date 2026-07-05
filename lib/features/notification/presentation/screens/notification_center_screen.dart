import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../controllers/notification_controller.dart';
import '../../data/models/isar_notification.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  final _searchCtrl = TextEditingController();
  int _activeTab = 0; // 0 = All, 1 = Unread

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref.read(notificationHistoryProvider.notifier).search(val);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(notificationHistoryProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'read_all') {
                ref.read(notificationHistoryProvider.notifier).markAllAsRead();
              } else if (val == 'clear_all') {
                _confirmClearAll(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(LucideIcons.checkSquare, size: 16),
                    SizedBox(width: 8),
                    Text('Mark all read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear all history', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search notifications...',
              leading: const Icon(LucideIcons.search, size: 20),
              onChanged: _onSearch,
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(colors.surfaceContainerHighest.withValues(alpha: 0.3)),
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),

          // Tabs Selection Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildTabButton(context, 0, 'All'),
                const SizedBox(width: 8),
                _buildTabButton(context, 1, 'Unread'),
              ],
            ),
          ),

          // Notifications History List
          Expanded(
            child: historyAsync.when(
              data: (notifications) {
                final list = _activeTab == 0
                    ? notifications
                    : notifications.where((n) => !n.isRead).toList();

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.bellOff, size: 48, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildNotificationCard(context, item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading history: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, int index, String label) {
    final isSelected = _activeTab == index;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _activeTab = index;
          });
        }
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, CachedNotification1816 item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    IconData leadingIcon = LucideIcons.bell;
    Color iconColor = colors.primary;

    if (item.type == 'homework') {
      leadingIcon = LucideIcons.bookOpen;
      iconColor = Colors.purple;
    } else if (item.type == 'fees') {
      leadingIcon = LucideIcons.wallet;
      iconColor = Colors.orange;
    } else if (item.type == 'attendance') {
      leadingIcon = LucideIcons.calendar;
      iconColor = Colors.green;
    }

    return Dismissible(
      key: Key('notif_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(notificationHistoryProvider.notifier).deleteNotification(item.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: item.isRead
                ? colors.outline.withValues(alpha: 0.08)
                : colors.primary.withValues(alpha: 0.25),
            width: item.isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            ref.read(notificationHistoryProvider.notifier).markAsRead(item.id);
            if (item.screen != null) {
              context.go(item.screen!);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon leading
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(leadingIcon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),

                // Text body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(item.receivedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 200.ms);
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This action will delete all received notifications history permanently. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notificationHistoryProvider.notifier).clearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
