import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart'; // kept for AuthException type
import '../services/api_client.dart';   // for ApiException

class AuthProvider extends ChangeNotifier {
  // Typed as dynamic so the provider accepts either the local AuthService
  // (local SQLite mode) OR the RemoteAuthService (HTTP mode). Both classes
  // implement the same method signatures (duck-typed).
  final dynamic _service;
  AuthProvider(this._service);

  User? _user;
  bool _bootstrapped = false;
  bool _loading = false;
  String? _error;

  User? get currentUser => _user;
  bool get isLoggedIn => _user != null;
  bool get bootstrapped => _bootstrapped;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> bootstrap() async {
    _user = await _service.currentUser;
    _bootstrapped = true;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.login(identifier, password);
      _loading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = 'Unexpected error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerStudent({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? studentId,
    String? department,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.registerStudent(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
        studentId: studentId,
        department: department,
      );
      _loading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = 'Unexpected error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createFirstAdmin({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _service.createUserByAdmin(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
        role: Role.admin,
        createdBy: 0,
      );
      _user = user;
      _loading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = 'Unexpected error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> needsInitialAdmin() => _service.needsInitialAdmin;
  Future<bool> selfRegistrationEnabled() => _service.selfRegistrationEnabled;

  /// Default loan period in days (from settings table).
  Future<int> defaultLoanDays() => _service.defaultLoanDays();

  /// Maximum active loans per student (from settings table).
  Future<int> maxActiveLoans() => _service.maxActiveLoans();

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_user == null) return false;
    try {
      await _service.changePassword(_user!.id!, currentPassword, newPassword);
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({String? fullName, String? department, String? email}) async {
    if (_user == null) return false;
    try {
      _user = await _service.updateProfile(
        _user!.id!,
        fullName: fullName,
        department: department,
        email: email,
      );
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Admin / librarian creates a new account on behalf of someone.
  Future<bool> createUserByAdmin({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? department,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createUserByAdmin(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
        role: role,
        studentId: studentId,
        department: department,
        createdBy: _user!.id!,
      );
      _loading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = 'Unexpected error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Admin deactivates a user account (preserves records).
  Future<void> deactivateUser(int userId) async {
    await _service.deactivate(userId, _user!.id!);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
