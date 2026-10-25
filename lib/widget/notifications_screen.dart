
import 'package:flutter/material.dart';

import '../model/notification_model.dart';
import '../service/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String? _error;

  int get _unreadCount =>
      _notifications.where((notification) => notification.isUnread).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications =
      await NotificationService.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isUnread) return;

    try {
      await NotificationService.markAsRead(notification.id);

      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere(
              (item) => item.id == notification.id,
        );

        if (index != -1) {
          final old = _notifications[index];
          _notifications[index] = NotificationModel(
            id: old.id,
            title: old.title,
            message: old.message,
            isRead: true,
            createdAt: old.createdAt,
            type: old.type,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark as read: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0 || _isMarkingAll) return;

    setState(() => _isMarkingAll = true);

    try {
      await NotificationService.markAllAsRead();

      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((item) {
          return NotificationModel(
            id: item.id,
            title: item.title,
            message: item.message,
            isRead: true,
            createdAt: item.createdAt,
            type: item.type,
          );
        }).toList();
        _isMarkingAll = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMarkingAll = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark all as read: $e')),
      );
    }
  }

  IconData _iconFor(String? type) {
    switch (type?.toUpperCase()) {
      case 'ASSIGNMENT':
      case 'NEW_ASSIGNMENT':
        return Icons.assignment_outlined;
      case 'REMINDER':
      case 'DEADLINE_REMINDER':
        return Icons.alarm_outlined;
      case 'ATTENDANCE':
        return Icons.fact_check_outlined;
      case 'CLASS':
      case 'TIMETABLE':
        return Icons.calendar_month_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'read_all') _markAllAsRead();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'read_all',
                enabled: _unreadCount > 0 && !_isMarkingAll,
                child: const Text('Mark all as read'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text('Could not load notifications'),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadNotifications,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _notifications.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.2,
            ),
            Icon(
              Icons.notifications_none,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('You’re all caught up!'),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'New assignment updates and reminders will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        )
            : ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_active),
                title: Text('$_unreadCount unread'),
                subtitle: const Text(
                  'Stay up to date with your college work',
                ),
                trailing: _isMarkingAll
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : TextButton(
                  onPressed: _unreadCount == 0
                      ? null
                      : _markAllAsRead,
                  child: const Text('Read all'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._notifications.map((notification) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: notification.isUnread
                    ? theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.35)
                    : null,
                child: ListTile(
                  onTap: () => _markAsRead(notification),
                  leading: CircleAvatar(
                    child: Icon(
                      _iconFor(notification.type),
                    ),
                  ),
                  title: Text(
                    notification.title ?? 'Notification',
                    style: TextStyle(
                      fontWeight: notification.isUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(notification.message ?? ''),
                        if (notification.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            notification.createdAt!
                                .toLocal()
                                .toString()
                                .substring(
                              0,
                              16,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: notification.isUnread
                      ? Icon(
                    Icons.circle,
                    size: 10,
                    color: theme.colorScheme.primary,
                  )
                      : const Icon(
                    Icons.check,
                    size: 18,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
