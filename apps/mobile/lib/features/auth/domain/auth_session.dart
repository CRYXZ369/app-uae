class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.email,
    required this.expiresAt,
    this.refreshToken,
    this.roles = const [],
  });

  final String accessToken;
  final String? refreshToken;
  final String email;
  final DateTime expiresAt;
  final List<String> roles;

  AuthSession withRoles(List<String> value) => AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    email: email,
    expiresAt: expiresAt,
    roles: List.unmodifiable(value),
  );

  bool get isExpired => !expiresAt.isAfter(DateTime.now());

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'email': email,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'roles': roles,
  };

  factory AuthSession.fromJson(Map<String, Object?> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final email = json['email'];
    final expiresAtValue = json['expiresAt'];
    final rolesValue = json['roles'];

    if (accessToken is! String ||
        accessToken.isEmpty ||
        (refreshToken != null && refreshToken is! String) ||
        (rolesValue != null && rolesValue is! List) ||
        email is! String ||
        expiresAtValue is! String) {
      throw const FormatException('Invalid stored authentication session.');
    }

    final expiresAt = DateTime.tryParse(expiresAtValue);
    if (expiresAt == null) {
      throw const FormatException('Invalid session expiration date.');
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken == null ? null : refreshToken as String,
      email: email,
      expiresAt: expiresAt,
      roles: rolesValue == null
          ? const []
          : (rolesValue as List).whereType<String>().toList(growable: false),
    );
  }
}
