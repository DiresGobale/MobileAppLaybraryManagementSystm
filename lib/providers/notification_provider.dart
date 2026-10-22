import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final dynamic _service; // NotificationService or RemoteNotificationService
  NotificationProvider(this._service);

  List<AppNotification> _items = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<AppNotification> get items => _items;
  int get unreadCount => _unreadCount;
  bool get isLoading => _loading;

  Future<void> loadForUser(int userId) async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _service.forUser(userId);
      _unreadCount = await _service.countUnread(userId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(int id, int userId) async {
    await _service.markRead(id);
    await loadForUser(userId);
  }

  Future<void> markAllRead(int userId) async {
    await _service.markAllRead(userId);
    await loadForUser(userId);
  }

  Future<void> delete(int id, int userId) async {
    await _service.delete(id);
    await loadForUser(userId);
  }
}
