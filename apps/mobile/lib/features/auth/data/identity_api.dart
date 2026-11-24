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
  IdentityApi(
    String baseUrl, {
    http.Client? client,
    bool allowPrivateHttp = false,
  }) : _baseUri = Uri.parse(baseUrl),
       _client = client ?? http.Client() {
    final loopback =
        _baseUri.host == 'localhost' || _baseUri.host == '127.0.0.1';
    final privateLanHost = allowPrivateHttp && _isPrivateIpv4(_baseUri.host);
    if (!_baseUri.hasAuthority ||
        _baseUri.userInfo.isNotEmpty ||
        _baseUri.hasQuery ||
        _baseUri.hasFragment ||
        _baseUri.path != '' && _baseUri.path != '/' ||
        (_baseUri.scheme != 'https' &&
            !(_baseUri.scheme == 'http' && (loopback || privateLanHost)))) {
      throw ArgumentError('La API requiere HTTPS o HTTP en localhost.');
    }
  }

  static bool _isPrivateIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((value) => value == null || value < 0 || value > 255)) {
      return false;
    }
    final first = octets[0]!;
    final second = octets[1]!;
    return first == 10 ||
        first == 192 && second == 168 ||
        first == 172 && second >= 16 && second <= 31;
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

  Future<List<String>?> currentRoles(String token) async {
    try {
      final response = await _send(
        'GET',
        '/current',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 401) return null;
      if (response.statusCode != 200) throw const IdentityApiException();
      final value = jsonDecode(response.body);
      if (value is! Map<String, dynamic> || value['roles'] is! List) {
        throw const IdentityApiException();
      }
      return (value['roles'] as List).whereType<String>().toList(
        growable: false,
      );
    } on http.ClientException {
      throw const IdentityApiException();
    } on TimeoutException {
      throw const IdentityApiException();
    } on FormatException {
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

  Future<List<Map<String, dynamic>>> getAcademicModule(
    String token,
    String module,
  ) async {
    const paths = {
      'Materias': 'subjects',
      'Horarios': 'schedule',
      'Tareas': 'tasks',
      'Asistencia': 'attendance',
      'Notificaciones': 'notifications',
      'Perfil': 'profile',
    };
    final path = paths[module];
    if (path == null) throw ArgumentError.value(module, 'module');
    try {
      final request = http.Request(
        'GET',
        _baseUri.resolve('/api/v1/academic/$path'),
      )..headers['Authorization'] = 'Bearer $token';
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(_timeout);
      if (response.statusCode != 200) throw const IdentityApiException();
      final value = jsonDecode(response.body);
      if (value is! List) throw const IdentityApiException();
      return value
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
    } on http.ClientException {
      throw const IdentityApiException();
    } on TimeoutException {
      throw const IdentityApiException();
    } on FormatException {
      throw const IdentityApiException();
    }
  }

  Future<void> saveTaskProgress(
    String token, {
    required int taskId,
    required String status,
    String? content,
  }) async {
    try {
      final request =
          http.Request(
              'POST',
              _baseUri.resolve('/api/v1/academic/tasks/progress'),
            )
            ..headers['Authorization'] = 'Bearer $token'
            ..headers['Content-Type'] = 'application/json'
            ..body = jsonEncode({
              'taskId': taskId,
              'status': status,
              'content': content,
            });
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(_timeout);
      if (response.statusCode != 204) throw const IdentityApiException();
    } on http.ClientException {
      throw const IdentityApiException();
    } on TimeoutException {
      throw const IdentityApiException();
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceRoster(
    String token,
    int scheduleId,
    DateTime date,
  ) async {
    try {
      final day =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      final uri = _baseUri
          .resolve('/api/v1/academic/attendance/roster')
          .replace(queryParameters: {'scheduleId': '$scheduleId', 'date': day});
      final request = http.Request('GET', uri)
        ..headers['Authorization'] = 'Bearer $token';
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(_timeout);
      if (response.statusCode != 200) throw const IdentityApiException();
      final value = jsonDecode(response.body);
      if (value is! List) throw const IdentityApiException();
      return value
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
    } on http.ClientException {
      throw const IdentityApiException();
    } on TimeoutException {
      throw const IdentityApiException();
    } on FormatException {
      throw const IdentityApiException();
    }
  }

  Future<void> recordAttendance(
    String token, {
    required int scheduleId,
    required int studentId,
    required DateTime date,
    required String status,
  }) async {
    try {
      final request =
          http.Request('POST', _baseUri.resolve('/api/v1/academic/attendance'))
            ..headers.addAll({
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            })
            ..body = jsonEncode({
              'idHorario': scheduleId,
              'idEstudiante': studentId,
              'fecha':
                  '${date.year.toString().padLeft(4, '0')}-'
                  '${date.month.toString().padLeft(2, '0')}-'
                  '${date.day.toString().padLeft(2, '0')}',
              'estado': status,
            });
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(_timeout);
      if (response.statusCode != 204) throw const IdentityApiException();
    } on http.ClientException {
      throw const IdentityApiException();
    } on TimeoutException {
      throw const IdentityApiException();
    }
  }

  void close() => _client.close();
}
