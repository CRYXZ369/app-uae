import 'dart:convert';

class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required List<String> roles,
  }) : roles = List.unmodifiable(roles) {
    if (accessToken.trim().isEmpty ||
        roles.isEmpty ||
        roles.any((role) => role.trim().isEmpty)) {
      throw ArgumentError('La sesión debe contener un token y roles válidos.');
    }
  }

  final String accessToken;
  final DateTime expiresAt;
  final List<String> roles;

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now);

  String encode() => jsonEncode({
    'accessToken': accessToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'roles': roles,
  });

  factory AuthSession.decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic> ||
        decoded['accessToken'] is! String ||
        decoded['expiresAt'] is! String ||
        decoded['roles'] is! List ||
        (decoded['roles'] as List).any((role) => role is! String)) {
      throw const FormatException('Los datos de sesión no son válidos.');
    }
    final expiresAt = DateTime.tryParse(decoded['expiresAt'] as String);
    if (expiresAt == null || !expiresAt.isUtc) {
      throw const FormatException('La fecha de sesión no es válida.');
    }
    try {
      return AuthSession(
        accessToken: decoded['accessToken'] as String,
        expiresAt: expiresAt,
        roles: List<String>.from(decoded['roles'] as List),
      );
    } on ArgumentError {
      throw const FormatException('Los datos de sesión no son válidos.');
    }
  }
}
