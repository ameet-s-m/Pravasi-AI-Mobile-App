// lib/screens/notification_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      title: 'Trip Completed Successfully',
      message: 'Your trip to NATPAC Office has been completed. View summary?',
      type: NotificationType.trip,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      action: 'View Summary',
    ),
    AppNotification(
      id: '2',
      title: 'Safety Alert',
      message: 'You deviated from your planned route. Are you safe?',
      type: NotificationType.safety,
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      action: 'I\'m Safe',
    ),
    AppNotification(
      id: '3',
      title: 'Weather Alert',
      message: 'Heavy rain expected in your area. Plan accordingly.',
      type: NotificationType.weather,
      time: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    AppNotification(
      id: '4',
      title: 'Reward Unlocked',
      message: 'You earned 50 points for completing 5 safe trips!',
      type: NotificationType.reward,
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: '5',
      title: 'Emergency Contact Added',
      message: 'Your emergency contact has been successfully added.',
      type: NotificationType.system,
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: '6',
      title: 'New Safe Zone Nearby',
      message: 'A new verified safe zone has been added near your location.',
      type: NotificationType.community,
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AppNotification(
      id: '7',
      title: 'Trip Reminder',
      message: 'You have a planned trip starting in 30 minutes.',
      type: NotificationType.trip,
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AppNotification(
      id: '8',
      title: 'Carbon Footprint Update',
      message: 'Your monthly carbon footprint: 12.5 kg CO2. Great job!',
      type: NotificationType.environment,
      time: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
    AppNotification(
      id: '9',
      title: 'Expense Added',
      message: 'New expense of ₹250 added to your trip.',
      type: NotificationType.expense,
      time: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
    AppNotification(
      id: '10',
      title: 'Route Verified',
      message: 'Your route has been verified as safe by the community.',
      type: NotificationType.community,
      time: DateTime.now().subtract(const Duration(days: 4)),
      isRead: true,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Notifications${_unreadCount > 0 ? ' ($_unreadCount)' : ''}'),
        trailing: _unreadCount > 0
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _markAllAsRead,
                child: const Text('Mark All Read'),
              )
            : null,
      ),
      child: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.bell_slash,
                    size: 64,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final isUnread = !notification.isRead;
    final timeAgo = _getTimeAgo(notification.time);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.systemRed,
        child: const Icon(
          CupertinoIcons.delete,
          color: CupertinoColors.white,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            _markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread
                ? CupertinoColors.systemBlue.withOpacity(0.1)
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? Border.all(
                    color: CupertinoColors.systemBlue.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: isUnread
                                  ? CupertinoColors.systemBlue
                                  : CupertinoColors.label,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: CupertinoColors.systemBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        if (notification.action != null) ...[
                          const SizedBox(width: 12),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _handleNotificationAction(notification),
                            child: Text(
                              notification.action!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getTypeColor(notification.type),
                                fontWeight: FontWeight.w600,
                              ),
                            ), minimumSize: Size(0, 0),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.trip:
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(notification.title),
            content: Text(notification.message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        break;
      case NotificationType.safety:
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Safety Check'),
            content: const Text('Are you safe? Do you need help?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('I\'m Safe'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Need Help'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        break;
      default:
        break;
    }
  }

  void _handleNotificationAction(AppNotification notification) {
    _markAsRead(notification.id);
    _handleNotificationTap(notification);
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.trip:
        return CupertinoColors.systemBlue;
      case NotificationType.safety:
        return CupertinoColors.systemRed;
      case NotificationType.weather:
        return CupertinoColors.systemTeal;
      case NotificationType.reward:
        return CupertinoColors.systemOrange;
      case NotificationType.community:
        return CupertinoColors.systemPurple;
      case NotificationType.expense:
        return CupertinoColors.systemGreen;
      case NotificationType.environment:
        return CupertinoColors.systemGreen;
      case NotificationType.system:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.trip:
        return CupertinoIcons.map;
      case NotificationType.safety:
        return CupertinoIcons.shield_fill;
      case NotificationType.weather:
        return CupertinoIcons.cloud_rain;
      case NotificationType.reward:
        return CupertinoIcons.star_fill;
      case NotificationType.community:
        return CupertinoIcons.person_2_fill;
      case NotificationType.expense:
        return CupertinoIcons.money_dollar_circle_fill;
      case NotificationType.environment:
        return CupertinoIcons.leaf_arrow_circlepath;
      case NotificationType.system:
        return CupertinoIcons.settings;
    }
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(time);
    }
  }
}

enum NotificationType {
  trip,
  safety,
  weather,
  reward,
  community,
  expense,
  environment,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime time;
  final bool isRead;
  final String? action;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    this.isRead = false,
    this.action,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? time,
    bool? isRead,
    String? action,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      action: action ?? this.action,
    );
  }
}
