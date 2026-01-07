class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  bool isRead;
  final String type; // 'low_stock', 'info', 'alert'

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.type = 'info',
  });
}
