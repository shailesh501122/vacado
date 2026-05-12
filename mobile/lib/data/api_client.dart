import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/env.dart';

class ApiException implements Exception {
  final int status;
  final String code;
  final String message;
  final dynamic details;
  ApiException(this.status, this.code, this.message, [this.details]);

  @override
  String toString() => 'ApiException($status $code): $message';
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(Env.apiBase);
    final cleanedPath = path.startsWith('/') ? path.substring(1) : path;
    final joinedPath = base.path.endsWith('/')
        ? '${base.path}$cleanedPath'
        : '${base.path}/$cleanedPath';
    return base.replace(
      path: joinedPath,
      queryParameters: query?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }

  Map<String, String> _headers([bool body = false]) {
    return {
      if (body) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send(() => _client.post(_uri(path), headers: _headers(true), body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) =>
      _send(() => _client.patch(_uri(path), headers: _headers(true), body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _send(() => _client.put(_uri(path), headers: _headers(true), body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers()));

  Future<dynamic> _send(Future<http.Response> Function() runner) async {
    try {
      final res = await runner().timeout(const Duration(seconds: 20));
      final ct = res.headers['content-type'] ?? '';
      final isJson = ct.contains('application/json');
      final decoded = isJson && res.body.isNotEmpty ? jsonDecode(res.body) : res.body;
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

      if (isJson && decoded is Map && decoded['error'] != null) {
        final err = decoded['error'] as Map;
        throw ApiException(
          res.statusCode,
          (err['code'] as String?) ?? 'error',
          (err['message'] as String?) ?? 'Request failed',
          err['details'],
        );
      }
      throw ApiException(res.statusCode, 'http_error', 'HTTP ${res.statusCode}');
    } on TimeoutException {
      throw ApiException(0, 'timeout', 'Request timed out');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'network_error', e.message);
    }
  }
}
