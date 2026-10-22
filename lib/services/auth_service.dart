import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../repositories/activity_log_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/constants.dart';
import '../utils/hash_utils.dart';

/// Authentication + user management service.
///
/// Local-only: credentials live in SQLite on this device. Cross-device auth
/// requires a backend (see README §2).
class AuthService {
  final UserRepository _users;
  final ActivityLogRepository _logs;
  final SettingsRepository _settings;
  final _sessionKey = 'iulms.session_user_id';

  AuthService(this._users, this._logs, this._settings);

  /// True if no users exist yet (first-admin setup flow).
  Future<bool> get needsInitialAdmin async => !(await _users.countAll() > 0);

  Future<bool> get selfRegistrationEnabled async =>
      await _settings.getBool(AppConstants.keySelfRegistration, defaultValue: true);

  Future<User?> get currentUser async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_sessionKey);
    if (id == null) return null;
    return _users.findById(id);
  }

  Future<User?> registerStudent({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? studentId,
    String? department,
  }) async {
    final enabled = await selfRegistrationEnabled;
    if (!enabled) {
      throw AuthException('Student self-registration is disabled. Contact the administrator.');
    }

    if (await _users.findByUsername(username) != null) {
      throw AuthException('Username is already taken.');
    }
    if (await _users.findByEmail(email) != null) {
      throw AuthException('Email is already registered.');
    }
    if (studentId != null && studentId.isNotEmpty) {
      if (await _users.findByStudentId(studentId) != null) {
        throw AuthException('Student ID is already registered.');
      }
    }

    final salt = HashUtils.generateSalt();
    final hash = HashUtils.hashPassword(password, salt);
    final now = DateTime.now();
    final user = User(
      fullName: fullName,
      username: username,
      email: email,
      passwordHash: hash,
      passwordSalt: salt,
      role: Role.student,
      studentId: studentId,
      department: department,
      createdAt: now,
      isActive: true,
    );
    final id = await _users.create(user);
    await _logs.create(ActivityLog(
      userId: id,
      action: AppConstants.actionUserAdd,
      details: 'Student $username self-registered',
      createdAt: now,
    ));
    final saved = await _users.findById(id);
    if (saved != null) await _persistSession(saved);
    return saved;
  }

  /// Creates an account by an administrator (librarian or admin).
  Future<User> createUserByAdmin({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? department,
    required int createdBy,
  }) async {
    if (role != Role.admin && role != Role.librarian && role != Role.student) {
      throw AuthException('Invalid role.');
    }
    if (await _users.findByUsername(username) != null) {
      throw AuthException('Username is already taken.');
    }
    if (await _users.findByEmail(email) != null) {
      throw AuthException('Email is already registered.');
    }
    if (role == Role.student && (studentId == null || studentId.isEmpty)) {
      throw AuthException('Students must have a Student ID.');
    }
    if (studentId != null && studentId.isNotEmpty) {
      if (await _users.findByStudentId(studentId) != null) {
        throw AuthException('Student ID is already registered.');
      }
    }
    final salt = HashUtils.generateSalt();
    final hash = HashUtils.hashPassword(password, salt);
    final now = DateTime.now();
    final user = User(
      fullName: fullName,
      username: username,
      email: email,
      passwordHash: hash,
      passwordSalt: salt,
      role: role,
      studentId: studentId,
      department: department,
      createdAt: now,
      isActive: true,
    );
    final id = await _users.create(user);
    await _logs.create(ActivityLog(
      userId: createdBy,
      action: AppConstants.actionUserAdd,
      details: 'Created $role account: $username',
      createdAt: now,
    ));
    final saved = await _users.findById(id);
    return saved!;
  }

  Future<User?> login(String identifier, String password) async {
    User? user;
    if (identifier.contains('@')) {
      user = await _users.findByEmail(identifier);
    } else {
      user = await _users.findByUsername(identifier);
    }
    if (user == null) {
      throw AuthException('No account found with that identifier.');
    }
    if (!user.isActive) {
      throw AuthException('Account is deactivated. Contact the administrator.');
    }
    final ok = HashUtils.verifyPassword(password, user.passwordSalt, user.passwordHash);
    if (!ok) {
      throw AuthException('Incorrect password. Please try again.');
    }
    await _persistSession(user);
    await _logs.create(ActivityLog(
      userId: user.id,
      action: AppConstants.actionLogin,
      details: '${user.username} signed in as ${user.role}',
      createdAt: DateTime.now(),
    ));
    return user;
  }

  Future<void> logout() async {
    final u = await currentUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    if (u != null) {
      await _logs.create(ActivityLog(
        userId: u.id,
        action: AppConstants.actionLogout,
        details: '${u.username} signed out',
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    final user = await _users.findById(userId);
    if (user == null) throw AuthException('Account not found.');
    final ok = HashUtils.verifyPassword(currentPassword, user.passwordSalt, user.passwordHash);
    if (!ok) {
      throw AuthException('Current password is incorrect.');
    }
    final salt = HashUtils.generateSalt();
    final hash = HashUtils.hashPassword(newPassword, salt);
    await _users.update(user.copyWith(passwordHash: hash, passwordSalt: salt));
    await _logs.create(ActivityLog(
      userId: userId,
      action: AppConstants.actionPasswordChange,
      details: '${user.username} changed password',
      createdAt: DateTime.now(),
    ));
    return true;
  }

  Future<User> updateProfile(int userId, {String? fullName, String? department, String? email}) async {
    final user = await _users.findById(userId);
    if (user == null) throw AuthException('Account not found.');
    if (email != null && email != user.email) {
      if (await _users.findByEmail(email) != null) {
        throw AuthException('Email already in use.');
      }
    }
    final updated = user.copyWith(
      fullName: fullName ?? user.fullName,
      department: department ?? user.department,
      email: email ?? user.email,
    );
    await _users.update(updated);
    await _logs.create(ActivityLog(
      userId: userId,
      action: AppConstants.actionProfileUpdate,
      details: '${user.username} updated profile',
      createdAt: DateTime.now(),
    ));
    final saved = await _users.findById(userId);
    // Refresh session
    if (saved != null) await _persistSession(saved);
    return saved!;
  }

  Future<List<User>> listUsers({String? roleFilter}) async {
    return _users.all(roleFilter: roleFilter);
  }

  Future<void> deactivate(int userId, int byAdminId) async {
    await _users.deactivate(userId);
    await _logs.create(ActivityLog(
      userId: byAdminId,
      action: AppConstants.actionUserDeactivate,
      details: 'Deactivated user #$userId',
      createdAt: DateTime.now(),
    ));
  }

  Future<void> reactivate(int userId, int byAdminId) async {
    await _users.reactivate(userId);
    await _logs.create(ActivityLog(
      userId: byAdminId,
      action: AppConstants.actionUserReactivate,
      details: 'Reactivated user #$userId',
      createdAt: DateTime.now(),
    ));
  }

  /// Hard delete of a user — refuses if the user still has loan records
  /// (the FK ON DELETE RESTRICT will throw otherwise).
  Future<void> deleteUser(int userId, int byAdminId) async {
    await _users.delete(userId);
    await _logs.create(ActivityLog(
      userId: byAdminId,
      action: AppConstants.actionUserDelete,
      details: 'Permanently deleted user #$userId',
      createdAt: DateTime.now(),
    ));
  }

  Future<void> _persistSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, user.id!);
  }

  Future<int> defaultLoanDays() async =>
      await _settings.getInt(AppConstants.keyLoanDays, defaultValue: 14);

  Future<int> maxActiveLoans() async =>
      await _settings.getInt(AppConstants.keyMaxActiveLoans, defaultValue: 3);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
