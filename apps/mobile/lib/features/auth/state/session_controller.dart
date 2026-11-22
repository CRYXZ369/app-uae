import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/session_store.dart';
import '../model/auth_session.dart';

enum SessionStatus { signedOut, processing, authenticated, expired, error }

class SessionController extends ChangeNotifier {
  SessionController(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SessionStore _store;
  final DateTime Function() _clock;
  Future<void> _pending = Future.value();
  Timer? _timer;
  AuthSession? _session;
  SessionStatus _status = SessionStatus.signedOut;
  Object? _error;
  bool _disposed = false;

  SessionStatus get status => _status;
  Object? get error => _error;

  Future<T> _run<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  void _setStatus(SessionStatus status, {Object? error}) {
    _status = status;
    _error = error;
    if (!_disposed) notifyListeners();
  }

  void _activate(AuthSession session) {
    _timer?.cancel();
    _session = session;
    _setStatus(SessionStatus.authenticated);
    if (!_disposed) {
      _timer = Timer(session.expiresAt.difference(_clock()), () {
        // Errors are exposed through status/error; there is no caller to await.
        unawaited(_expireIfCurrent(session).catchError((Object _) {}));
      });
    }
  }

  Future<void> _clear(SessionStatus status) async {
    _timer?.cancel();
    _session = null;
    _setStatus(SessionStatus.processing);
    try {
      await _store.delete();
      _setStatus(status);
    } catch (error) {
      _setStatus(SessionStatus.error, error: error);
      rethrow;
    }
  }

  Future<void> _expireIfCurrent(AuthSession session) => _run(() async {
    if (identical(_session, session)) {
      if (session.isExpiredAt(_clock())) {
        await _clear(SessionStatus.expired);
      } else {
        _activate(session);
      }
    }
  });

  Future<void> restore() => _run(() async {
    _timer?.cancel();
    _session = null;
    _setStatus(SessionStatus.processing);
    try {
      final session = await _store.read();
      if (session == null) {
        _setStatus(SessionStatus.signedOut);
      } else if (session.isExpiredAt(_clock())) {
        await _clear(SessionStatus.expired);
      } else {
        _activate(session);
      }
    } catch (error) {
      _setStatus(SessionStatus.error, error: error);
      rethrow;
    }
  });

  Future<void> save(AuthSession session) => _run(() async {
    if (session.isExpiredAt(_clock())) {
      throw ArgumentError('No se puede guardar una sesión expirada.');
    }
    _timer?.cancel();
    _session = null;
    _setStatus(SessionStatus.processing);
    try {
      await _store.write(session);
      if (session.isExpiredAt(_clock())) {
        await _clear(SessionStatus.expired);
      } else {
        _activate(session);
      }
    } catch (error) {
      _setStatus(SessionStatus.error, error: error);
      rethrow;
    }
  });

  Future<AuthSession?> sessionForRequest() => _run(() async {
    final session = _session;
    if (session != null && session.isExpiredAt(_clock())) {
      await _clear(SessionStatus.expired);
      return null;
    }
    return session;
  });

  Future<void> signOut() => _run(() => _clear(SessionStatus.signedOut));

  Future<void> handleHttpStatus(int statusCode, String requestToken) =>
      _run(() async {
        if (statusCode == 401 && _session?.accessToken == requestToken) {
          await _clear(SessionStatus.expired);
        }
      });

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
