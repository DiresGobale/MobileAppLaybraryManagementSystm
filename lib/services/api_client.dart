import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/backend_config.dart';

/// Thrown by [ApiClient] when the backend returns a non-2xx response OR when
/// the device cannot reach the backend. Carries the server's error code so
/// the UI can show a friendly message.
class ApiException implements Exception {
  final int? status;
  final String message;
  final String? code;
  final Map<String, dynamic>? body;

  ApiException(this.message, {this.status, this.code, this.body});

  @override
  String toString() => 'ApiException($status $code): $message';
}

/// Singleton HTTP client used by every Remote* service. Handles:
/// - Base URL resolution (from `BackendConfig`)
/// - JSON encoding/decoding
/// - Bearer JWT injection (stored in SharedPreferences after login)
/// - Error mapping to `ApiException` with the server's `{ error, code }` shape
/// - Timeout (10s default) so the UI doesn't hang when the backend is down
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _tokenKey = 'iulms.jwt';
  static const Duration _timeout = Duration(seconds: 10);

  String get base => BackendConfig.instance.baseUrl.replaceFirst(
      RegExp(r'/+$'), ''); // strip trailing slash

  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String jwt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jwt);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (extra != null) h.addAll(extra);
    return h;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _readToken();
    final h = _headers();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ----------------- HTTP verbs -----------------

  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    final uri = _buildUri(path, query);
    final res = await http.get(uri, headers: await _authHeaders()).timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    final res = await http
        .post(uri, headers: await _authHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> patchJson(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    final res = await http
        .patch(uri, headers: await _authHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
    return _decode(res);
  }

  Future<dynamic> deleteJson(String path) async {
    final uri = _buildUri(path);
    final res = await http.delete(uri, headers: await _authHeaders()).timeout(_timeout);
    return _decode(res);
  }

  /// Raw text/CSV download — used by the Reports screen for CSV export.
  Future<String> getText(String path, {Map<String, dynamic>? query}) async {
    final uri = _buildUri(path, query);
    final res = await http.get(uri, headers: await _authHeaders()).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}', status: res.statusCode);
    }
    return res.body;
  }

  // ----------------- helpers -----------------

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final cleaned = path.startsWith('/') ? path : '/$path';
    final base = BackendConfig.instance.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (query == null || query.isEmpty) {
      return Uri.parse('$base$cleaned');
    }
    final qs = <String, String>{};
    query.forEach((k, v) {
      if (v != null) qs[k] = v.toString();
    });
    return Uri.parse('$base$cleaned').replace(queryParameters: qs);
  }

  dynamic _decode(http.Response res) {
    dynamic body;
    try {
      body = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      body = res.body;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    // Error response — extract { error, code } if present.
    final msg = (body is Map) ? (body['error'] as String? ?? res.reasonPhrase) : res.reasonPhrase;
    final code = (body is Map) ? (body['code'] as String?) : null;
    throw ApiException(msg ?? 'Request failed', status: res.statusCode, code: code, body: body is Map ? body : null);
  }
}
