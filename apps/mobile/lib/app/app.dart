import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/widgets/app_error_screen.dart';
import '../core/widgets/app_loading_screen.dart';
import '../core/session/secure_session_store.dart';
import '../core/session/session_store.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/data/identity_api.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/session_expired_screen.dart';
import '../features/home/presentation/home_screen.dart';

class AppUae extends StatefulWidget {
  const AppUae({
    super.key,
    this.sessionStore,
    this.onLogin,
    this.clock,
    this.identityApi,
  });

  final SessionStore? sessionStore;
  final LoginHandler? onLogin;
  final DateTime Function()? clock;
  final IdentityApi? identityApi;

  @override
  State<AppUae> createState() => _AppUaeState();
}

class _AppUaeState extends State<AppUae> {
  late final SessionStore _sessionStore =
      widget.sessionStore ?? SecureSessionStore();
  AuthSession? _session;
  bool _isRestoringSession = true;
  bool _sessionRestoreFailed = false;
  bool _apiUnavailable = false;
  bool _sessionExpired = false;
  Timer? _expirationTimer;
  static const _apiUrl = String.fromEnvironment('API_BASE_URL');
  late final IdentityApi? _api =
      widget.identityApi ?? (_apiUrl.isEmpty ? null : IdentityApi(_apiUrl));

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  void _scheduleExpiration(AuthSession session) {
    _expirationTimer?.cancel();
    _expirationTimer = Timer(session.expiresAt.difference(_now), () {
      if (!mounted || !identical(_session, session)) return;
      if (session.expiresAt.isAfter(_now)) {
        _scheduleExpiration(session);
      } else {
        _expireSession();
      }
    });
  }

  Future<void> _expireSession() async {
    _expirationTimer?.cancel();
    setState(() {
      _session = null;
      _isRestoringSession = true;
      _sessionRestoreFailed = false;
      _apiUnavailable = false;
    });
    try {
      await _sessionStore.clear();
      if (!mounted) return;
      setState(() {
        _sessionExpired = true;
        _isRestoringSession = false;
      });
    } on SessionStorageException {
      if (!mounted) return;
      setState(() {
        _sessionRestoreFailed = true;
        _isRestoringSession = false;
      });
    }
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    if (widget.identityApi == null) _api?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _isRestoringSession = true;
      _sessionRestoreFailed = false;
      _apiUnavailable = false;
    });

    try {
      var session = await _sessionStore.read();
      var expired = session != null && !session.expiresAt.isAfter(_now);
      if (!expired && session != null && _api != null) {
        final roles = await _api.currentRoles(session.accessToken);
        expired = roles == null;
        if (roles != null) {
          session = session.withRoles(roles);
          await _sessionStore.write(session);
        }
      }
      if (session != null && !session.expiresAt.isAfter(_now)) {
        expired = true;
      }
      if (expired) {
        await _sessionStore.clear();
        session = null;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _session = session;
        _sessionExpired = expired;
        _isRestoringSession = false;
      });
      if (session != null) _scheduleExpiration(session);
    } on IdentityApiException {
      if (mounted) {
        setState(() {
          _apiUnavailable = true;
          _sessionRestoreFailed = true;
          _isRestoringSession = false;
        });
      }
    } on SessionStorageException {
      if (mounted) {
        setState(() {
          _sessionRestoreFailed = true;
          _isRestoringSession = false;
        });
      }
    }
  }

  Future<LoginResult> _login(String email, String password) async {
    final handler = widget.onLogin ?? _api?.login;
    final result = handler == null
        ? const LoginResult.unavailable()
        : await handler(email, password);

    if (result.status == LoginStatus.authenticated) {
      final session = result.session;
      if (session == null) {
        return const LoginResult.unavailable();
      }
      if (!session.expiresAt.isAfter(_now)) {
        return const LoginResult.unavailable();
      }
      try {
        await _sessionStore.write(session);
        if (!session.expiresAt.isAfter(_now)) {
          await _sessionStore.clear();
          return const LoginResult.unavailable();
        }
      } on SessionStorageException {
        if (_api != null && widget.onLogin == null) {
          try {
            await _api.revoke(session.accessToken);
          } on IdentityApiException {
            return const LoginResult.unavailable();
          }
        }
        return const LoginResult.sessionStorageFailure();
      }
      if (mounted) {
        setState(() => _session = session);
        _scheduleExpiration(session);
      }
    }
    return result;
  }

  Future<void> _logout() async {
    _expirationTimer?.cancel();
    try {
      final session = _session;
      if (_api != null && session != null) {
        await _api.revoke(session.accessToken);
      }
      await _sessionStore.clear();
    } on IdentityApiException {
      final session = _session;
      if (mounted && session != null) _scheduleExpiration(session);
      throw const SessionStorageException();
    } on SessionStorageException {
      final session = _session;
      if (mounted && session != null) _scheduleExpiration(session);
      rethrow;
    }
    if (mounted) {
      setState(() {
        _session = null;
        _sessionExpired = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Unificada UAE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff214b78),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff4f7fb),
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: const Color(0xff16365c).withValues(alpha: .08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xffe9eef5)),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffdce4ef)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffdce4ef)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xff315d96), width: 1.6),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xffe6efff),
          elevation: 8,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
      home: _isRestoringSession
          ? const AppLoadingScreen(message: 'Recuperando sesión...')
          : _sessionRestoreFailed
          ? AppErrorScreen(
              title: 'No se pudo recuperar la sesión',
              message: _apiUnavailable
                  ? 'No fue posible verificar la sesión con el servicio.'
                  : 'No fue posible acceder al almacenamiento seguro del dispositivo.',
              actionLabel: 'Reintentar',
              onAction: (_) => _restoreSession(),
            )
          : _sessionExpired
          ? SessionExpiredScreen(
              onSignIn: () => setState(() => _sessionExpired = false),
            )
          : _session == null
          ? LoginScreen(onLogin: _login)
          : HomeScreen(
              onLogout: _logout,
              email: _session!.email,
              roles: _session!.roles,
              loadCourseGrades: () =>
                  _api!.getCourseGrades(_session!.accessToken),
              loadAcademicModule: (module) =>
                  _api!.getAcademicModule(_session!.accessToken, module),
              loadAttendanceRoster: (scheduleId, date) => _api!
                  .getAttendanceRoster(_session!.accessToken, scheduleId, date),
              saveAttendance: (scheduleId, studentId, date, status) =>
                  _api!.recordAttendance(
                    _session!.accessToken,
                    scheduleId: scheduleId,
                    studentId: studentId,
                    date: date,
                    status: status,
                  ),
              saveTaskProgress: (taskId, status, {content}) =>
                  _api!.saveTaskProgress(
                    _session!.accessToken,
                    taskId: taskId,
                    status: status,
                    content: content,
                  ),
            ),
      onUnknownRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => AppErrorScreen(
          title: 'Pantalla no encontrada',
          message: 'No se encontró la pantalla solicitada.',
          actionLabel: 'Continuar',
          onAction: (context) => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
