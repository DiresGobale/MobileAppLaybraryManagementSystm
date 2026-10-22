import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Operating mode for the Flutter app:
/// - **local**: reads/writes go to on-device SQLite via the existing
///   `AuthService` / `BookService` / `LoanService` / etc.
/// - **remote**: reads/writes go to the Node.js backend via HTTP
///   (`RemoteAuthService` / `RemoteBookService` / etc.).
///
/// The mode is persisted in SharedPreferences (`data_source_mode`) so it
/// survives restarts. To switch modes at runtime, change the setting in
/// Settings → Backend and the app picks it up on next launch.
enum DataSourceMode { local, remote }

/// Singleton that holds the active data-source mode + the backend base URL.
/// Read once at app startup (in `app_routes.dart`'s `providers()` method) to
/// decide which set of services to wire into the Provider tree.
class BackendConfig {
  BackendConfig._();
  static final BackendConfig instance = BackendConfig._();

  DataSourceMode _mode = DataSourceMode.local;
  String _baseUrl = 'http://10.0.2.2:4000';
  bool _bootstrapped = false;

  DataSourceMode get mode => _mode;
  String get baseUrl => _baseUrl;
  bool get isRemote => _mode == DataSourceMode.remote;
  bool get isLocal => _mode == DataSourceMode.local;
  bool get bootstrapped => _bootstrapped;

  /// Loads mode + URL from SharedPreferences. Idempotent — safe to call
  /// multiple times. Called from `app_routes.providers()` at startup.
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(AppConstants.keyDataSourceMode) ?? 'local';
    _mode = modeStr == 'remote' ? DataSourceMode.remote : DataSourceMode.local;
    _baseUrl =
        prefs.getString(AppConstants.keyBackendUrl) ?? 'http://10.0.2.2:4000';
    _bootstrapped = true;
  }

  /// Persist a new mode. Takes effect on next app launch (the Provider tree
  /// is wired once at startup; switching at runtime would invalidate cached
  /// state across all providers).
  Future<void> setMode(DataSourceMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.keyDataSourceMode, mode == DataSourceMode.remote ? 'remote' : 'local');
  }

  /// Persist a new backend URL. Takes effect on next launch (and on the
  /// next /health probe).
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyBackendUrl, url);
  }
}
