import '../models/library_info.dart';
import '../models/activity_log.dart';
import '../repositories/activity_log_repository.dart';
import '../repositories/library_info_repository.dart';
import '../utils/constants.dart';

/// Service layer for the landing page (About / Services / How It Works / Contact).
/// All data is sourced from the local SQLite database so the user sees
/// exactly what an administrator has configured — never hardcoded copy.
/// Every CRUD operation is logged to `activity_logs` with the actor's user id.
class LibraryInfoService {
  final LibraryInfoRepository _repo;
  final ActivityLogRepository _logs;
  LibraryInfoService(this._repo, this._logs);

  /// Exposes the activity log repository so screens can build custom views
  /// without needing their own DB connection. (Activity Log screen.)
  ActivityLogRepository get activityLogs => _logs;

  Future<List<LibraryService>> services() => _repo.services(activeOnly: true);
  Future<List<LibraryStep>> steps() => _repo.steps(activeOnly: true);
  Future<LibraryContactInfo> contactInfo() => _repo.fetchContactInfo();

  Future<int> saveService(LibraryService s, {int? actorId, bool isNew = false}) async {
    final id = await _repo.upsertService(s);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: isNew ? AppConstants.actionServiceAdd : AppConstants.actionServiceEdit,
      details: '${isNew ? "Added" : "Updated"} service: ${s.title}',
      createdAt: DateTime.now(),
    ));
    return id;
  }

  Future<void> deleteService(int id, {int? actorId, String? title}) async {
    await _repo.deleteService(id);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: AppConstants.actionServiceDelete,
      details: 'Deleted service #$id${title != null ? ' ($title)' : ''}',
      createdAt: DateTime.now(),
    ));
  }

  Future<int> saveStep(LibraryStep s, {int? actorId, bool isNew = false}) async {
    final id = await _repo.upsertStep(s);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: isNew ? AppConstants.actionStepAdd : AppConstants.actionStepEdit,
      details: '${isNew ? "Added" : "Updated"} step: ${s.title}',
      createdAt: DateTime.now(),
    ));
    return id;
  }

  Future<void> deleteStep(int id, {int? actorId, String? title}) async {
    await _repo.deleteStep(id);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: AppConstants.actionStepDelete,
      details: 'Deleted step #$id${title != null ? ' ($title)' : ''}',
      createdAt: DateTime.now(),
    ));
  }

  Future<int> submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final id = await _repo.submitContactMessage(ContactMessage(
      name: name,
      email: email,
      subject: subject,
      message: message,
      submittedAt: DateTime.now(),
    ));
    // Log to the activity feed so admins see new messages in real-time.
    await _logs.create(ActivityLog(
      userId: null,
      action: AppConstants.actionContactReceived,
      details: 'Contact form: "$subject" from $name <$email>',
      createdAt: DateTime.now(),
    ));
    return id;
  }

  Future<List<ContactMessage>> inbox({bool unhandledOnly = false}) =>
      _repo.contactMessages(unhandledOnly: unhandledOnly);

  Future<void> markContactHandled(int id, {int? actorId}) async {
    await _repo.markContactHandled(id);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: AppConstants.actionContactHandled,
      details: 'Marked contact message #$id as handled',
      createdAt: DateTime.now(),
    ));
  }

  Future<void> deleteContactMessage(int id, {int? actorId}) async {
    await _repo.deleteContactMessage(id);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: AppConstants.actionContactDeleted,
      details: 'Deleted contact message #$id',
      createdAt: DateTime.now(),
    ));
  }

  /// Persist a single library-info setting (used by the admin editor).
  /// Logs the change with the actor's user id.
  Future<void> setSetting(String key, String value, {int? actorId}) async {
    await _repo.setSetting(key, value);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: AppConstants.actionLibraryInfoEdit,
      details: 'Updated setting "$key"',
      createdAt: DateTime.now(),
    ));
  }
}
