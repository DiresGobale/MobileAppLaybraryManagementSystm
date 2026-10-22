import 'package:flutter/foundation.dart';

import '../models/library_info.dart';
import '../models/report.dart';
import '../services/library_info_service.dart';
import '../services/report_service.dart';

/// Provides all data for the landing page (5 sections):
/// - Hero (uses DashboardProvider elsewhere)
/// - About (contact info + live stats)
/// - Services (library_services table)
/// - How It Works (library_steps table)
/// - Contact (contact info + form submission)
class LandingProvider extends ChangeNotifier {
  final dynamic _info; // LibraryInfoService or RemoteLibraryInfoService
  final dynamic _reports; // ReportService or RemoteReportService

  LandingProvider(this._info, this._reports);

  LibraryContactInfo? _contact;
  List<LibraryService> _services = [];
  List<LibraryStep> _steps = [];
  DashboardStats? _stats;
  bool _loading = false;
  String? _error;

  LibraryContactInfo? get contact => _contact;
  List<LibraryService> get services => _services;
  List<LibraryStep> get steps => _steps;
  DashboardStats? get stats => _stats;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _info.contactInfo(),
        _info.services(),
        _info.steps(),
        _reports.dashboardStats(),
      ]);
      _contact = results[0] as LibraryContactInfo;
      _services = results[1] as List<LibraryService>;
      _steps = results[2] as List<LibraryStep>;
      _stats = results[3] as DashboardStats;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      await _info.submitContactMessage(
        name: name,
        email: email,
        subject: subject,
        message: message,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
