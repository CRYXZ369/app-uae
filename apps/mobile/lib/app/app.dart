import 'package:material_ui/material_ui.dart';

import '../core/widgets/app_error_screen.dart';
import '../core/widgets/app_loading_screen.dart';
import '../core/session/secure_session_store.dart';
import '../core/session/session_store.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';

class AppUae extends StatefulWidget {
  const AppUae({super.key, this.sessionStore, this.onLogin});

  final SessionStore? sessionStore;
  final LoginHandler? onLogin;

  @override
  State<AppUae> createState() => _AppUaeState();
}

class _AppUaeState extends State<AppUae> {
  late final SessionStore _sessionStore =
      widget.sessionStore ?? SecureSessionStore();
  AuthSession? _session;
  bool _isRestoringSession = true;
  bool _sessionRestoreFailed = false;

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
      if (session?.isExpired ?? false) {
        await _sessionStore.clear();
        session = null;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _session = session;
        _isRestoringSession = false;
      });
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
      try {
        await _sessionStore.write(session);
      } on SessionStorageException {
        return const LoginResult.sessionStorageFailure();
      }
      if (mounted) {
        setState(() => _session = session);
      }
    }
    return result;
  }

  Future<void> _logout() async {
    await _sessionStore.clear();
    if (mounted) {
      setState(() => _session = null);
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
