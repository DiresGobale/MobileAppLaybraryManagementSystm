import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository _repo;
  NotificationService(this._repo);

  Future<List<AppNotification>> forUser(int userId, {bool unreadOnly = false}) =>
      _repo.forUser(userId, unreadOnly: unreadOnly);

  Future<int> countUnread(int userId) => _repo.countUnread(userId);

  Future<void> markRead(int id) => _repo.markRead(id);

  Future<void> markAllRead(int userId) => _repo.markAllRead(userId);

  Future<int> delete(int id) => _repo.delete(id);
}
