import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/auth_session.dart';

abstract interface class SessionStore {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> delete();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );

  static const _key = 'auth_session';
  final FlutterSecureStorage _storage;

  void _checkPlatform() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError(
        'El almacenamiento de sesión solo está habilitado en Android y iOS.',
      );
    }
  }

  @override
  Future<AuthSession?> read() async {
    _checkPlatform();
    final value = await _storage.read(key: _key);
    return value == null ? null : AuthSession.decode(value);
  }

  @override
  Future<void> write(AuthSession session) async {
    _checkPlatform();
    await _storage.write(key: _key, value: session.encode());
  }

  @override
  Future<void> delete() async {
    _checkPlatform();
    await _storage.delete(key: _key);
  }
}
