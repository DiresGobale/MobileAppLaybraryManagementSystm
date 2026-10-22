import 'package:flutter/foundation.dart';

import '../models/report.dart';
import '../services/report_service.dart';

class DashboardProvider extends ChangeNotifier {
  final dynamic _service; // ReportService or RemoteReportService
  DashboardProvider(this._service);

  DashboardStats? _stats;
  BookInventorySummary? _inventory;
  List<PopularBook> _popular = [];
  bool _loading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  BookInventorySummary? get inventory => _inventory;
  List<PopularBook> get popular => _popular;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _service.dashboardStats();
      _inventory = await _service.inventorySummary();
      _popular = await _service.popularBooks(limit: 5);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
