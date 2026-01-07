import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../models/product.dart';

class NotificationProvider with ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  bool checkLowStock(List<Product> products) {
    bool hasNewAlerts = false;
    for (var product in products) {
      if (product.stockQuantity <= product.lowStockLimit) {
        // Check if we already have a recent unread notification for this product
        final hasRecentNotification = _notifications.any((n) => 
          n.type == 'low_stock' && 
          n.message.contains(product.name) && 
          !n.isRead
        );

        if (!hasRecentNotification) {
          addNotification(
            AppNotification(
              id: DateTime.now().millisecondsSinceEpoch.toString() + product.id.toString(),
              title: 'Low Stock Alert',
              message: '${product.name} is running low on stock (${product.stockQuantity} remaining).',
              date: DateTime.now(),
              type: 'low_stock',
            ),
          );
          hasNewAlerts = true;
        }
      }
    }
    return hasNewAlerts;
  }
}
