import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/auth_session.dart';
import '../presentation/login_screen.dart';
import '../../grades/domain/course_grade_summary.dart';

class IdentityApiException implements Exception {
  const IdentityApiException();
}

class IdentityApi {
  IdentityApi(String baseUrl, {http.Client? client})
    : _baseUri = Uri.parse(baseUrl),
      _client = client ?? http.Client() {
    final loopback =
        _baseUri.host == 'localhost' || _baseUri.host == '127.0.0.1';
    if (!_baseUri.hasAuthority ||
        _baseUri.userInfo.isNotEmpty ||
        _baseUri.hasQuery ||
        _baseUri.hasFragment ||
        _baseUri.path != '' && _baseUri.path != '/' ||
        (_baseUri.scheme != 'https' &&
            !(_baseUri.scheme == 'http' && loopback))) {
      throw ArgumentError('La API requiere HTTPS o HTTP en localhost.');
    }
  }

  final Uri _baseUri;
  final http.Client _client;
  static const _timeout = Duration(seconds: 15);

  Uri _endpoint(String path) => _baseUri.resolve('/api/v1/sessions$path');

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String> headers = const {},
    String? body,
  }) async {
    final request = http.Request(method, _endpoint(path))
      ..followRedirects = false
      ..headers.addAll(headers);
    if (body != null) request.body = body;
    final streamed = await _client.send(request).timeout(_timeout);
    return http.Response.fromStream(streamed).timeout(_timeout);
  }

  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await _send(
        'POST',
        '',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 401) {
        return const LoginResult.invalidCredentials();
      }
      if (response.statusCode != 200) return const LoginResult.unavailable();
      final value = jsonDecode(response.body);
      if (value is! Map<String, dynamic>) {
        return const LoginResult.unavailable();
      }
      final session = AuthSession.fromJson(value);
      if (session.isExpired) return const LoginResult.unavailable();
      return LoginResult.authenticated(session);
    } on http.ClientException {
      return const LoginResult.unavailable();
    } on TimeoutException {
      return const LoginResult.unavailable();
    } on FormatException {
      return const LoginResult.unavailable();
    }
  }

  Future<bool> isSessionValid(String token) async {
    try {
      final response = await _send(
        'GET',
        '/current',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return true;
      if (response.statusCode == 401) return false;
      throw const IdentityApiException();
    } on http.ClientException {
      throw const IdentityApiException();
    } on TimeoutException {
      throw const IdentityApiException();
    }
  }

  Future<void> revoke(String token) async {
    try {
      final response = await _send(
        'POST',
        '/current/revoke',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 204 && response.statusCode != 401) {
        throw const IdentityApiException();
      }
    } on http.ClientException {
      throw const IdentityApiException();
    } on TimeoutException {
      throw const IdentityApiException();
    }
  }

  Future<List<CourseGradeSummary>> getCourseGrades(String token) async {
    try {
      final request = http.Request(
        'GET',
        _baseUri.resolve('/api/v1/grades/courses'),
      )..headers['Authorization'] = 'Bearer $token';
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(_timeout);
      if (response.statusCode != 200) throw const IdentityApiException();
      final value = jsonDecode(response.body);
      if (value is! List) throw const IdentityApiException();
      return value
          .map(
            (item) => CourseGradeSummary.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on http.ClientException {
      throw const IdentityApiException();
    } on TimeoutException {
      throw const IdentityApiException();
    } on FormatException {
      throw const IdentityApiException();
    }
  }

  void close() => _client.close();
}
