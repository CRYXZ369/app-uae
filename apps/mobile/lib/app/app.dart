import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/widgets/app_error_screen.dart';
import '../core/widgets/app_loading_screen.dart';
import '../core/session/secure_session_store.dart';
import '../core/session/session_store.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/session_expired_screen.dart';
import '../features/home/presentation/home_screen.dart';

class AppUae extends StatefulWidget {
  const AppUae({super.key, this.sessionStore, this.onLogin, this.clock});

  final SessionStore? sessionStore;
  final LoginHandler? onLogin;
  final DateTime Function()? clock;

  @override
  State<AppUae> createState() => _AppUaeState();
}

class _AppUaeState extends State<AppUae> {
  late final SessionStore _sessionStore =
      widget.sessionStore ?? SecureSessionStore();
  AuthSession? _session;
  bool _isRestoringSession = true;
  bool _sessionRestoreFailed = false;
  bool _sessionExpired = false;
  Timer? _expirationTimer;

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
    });

    try {
      var session = await _sessionStore.read();
      final expired = session != null && !session.expiresAt.isAfter(_now);
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
    final handler = widget.onLogin;
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
      await _sessionStore.clear();
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
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: _isRestoringSession
          ? const AppLoadingScreen(message: 'Recuperando sesión...')
          : _sessionRestoreFailed
          ? AppErrorScreen(
              title: 'No se pudo recuperar la sesión',
              message: 'No fue posible acceder al almacenamiento seguro del dispositivo.',
              actionLabel: 'Reintentar',
              onAction: (_) => _restoreSession(),
            )
          : _sessionExpired
          ? SessionExpiredScreen(
              onSignIn: () => setState(() => _sessionExpired = false),
            )
          : _session == null
          ? LoginScreen(onLogin: _login)
          : HomeScreen(onLogout: _logout),
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
