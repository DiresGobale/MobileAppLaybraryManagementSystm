import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/backend_config.dart';
import '../utils/constants.dart';

/// Holds the current data-source mode + backend URL, exposes a `testConnection`
/// method, and notifies listeners when the mode flips. The mode is read at app
/// startup by [AppRoutes.providers] to decide whether to wire local or remote
/// services into the Provider tree. Changing the mode at runtime persists it
/// to SharedPreferences and prompts the user to relaunch the app.
class DataSourceProvider extends ChangeNotifier {
  DataSourceMode _mode = DataSourceMode.local;
  String _baseUrl = 'http://10.0.2.2:4000';
  bool _isConnected = false;
  String? _lastError;

  DataSourceMode get mode => _mode;
  String get baseUrl => _baseUrl;
  bool get isRemote => _mode == DataSourceMode.remote;
  bool get isLocal => _mode == DataSourceMode.local;
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;

  /// Bootstrap from SharedPreferences. Called once at app startup.
  Future<void> bootstrap() async {
    await BackendConfig.instance.bootstrap();
    _mode = BackendConfig.instance.mode;
    _baseUrl = BackendConfig.instance.baseUrl;
    notifyListeners();
    if (isRemote) {
      // Try a health probe so the UI shows "Connected" / "Offline".
      await testConnection();
    }
  }

  Future<void> setMode(DataSourceMode mode) async {
    _mode = mode;
    await BackendConfig.instance.setMode(mode);
    notifyListeners();
    if (isRemote) await testConnection();
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    await BackendConfig.instance.setBaseUrl(url);
    notifyListeners();
    if (isRemote) await testConnection();
  }

  /// Hits `GET /health` on the backend. Updates [_isConnected] + [_lastError].
  Future<bool> testConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      _isConnected = res.statusCode == 200;
      _lastError = _isConnected ? null : 'HTTP ${res.statusCode}';
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
    }
    notifyListeners();
    return _isConnected;
  }
}
