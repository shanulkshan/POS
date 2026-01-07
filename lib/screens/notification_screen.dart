import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Unread'),
              Tab(text: 'Read'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () {
                Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
              },
              tooltip: 'Mark all as read',
            ),
          ],
        ),
        body: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            final unreadNotifications = provider.notifications.where((n) => !n.isRead).toList();
            final readNotifications = provider.notifications.where((n) => n.isRead).toList();

            return TabBarView(
              children: [
                _buildNotificationList(context, provider, unreadNotifications, isUnreadTab: true),
                _buildNotificationList(context, provider, readNotifications, isUnreadTab: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context, NotificationProvider provider, List<AppNotification> notifications, {required bool isUnreadTab}) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUnreadTab ? Icons.notifications_none : Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              isUnreadTab ? 'No unread notifications' : 'No read notifications',
              style: const TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Dismissible(
          key: Key(notification.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            provider.removeNotification(notification.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification removed')),
            );
          },
          child: Container(
            color: notification.isRead ? Colors.white : Colors.orange.withOpacity(0.05),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: notification.type == 'low_stock' ? Colors.red[100] : Colors.blue[100],
                child: Icon(
                  notification.type == 'low_stock' ? Icons.warning_amber : Icons.info_outline,
                  color: notification.type == 'low_stock' ? Colors.red : Colors.blue,
                ),
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(notification.message),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(notification.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              onTap: () {
                if (!notification.isRead) {
                  provider.markAsRead(notification.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
