import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/auth_session.dart';
import 'session_store.dart';

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );

  static const _sessionKey = 'university_app_session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    try {
      final encodedSession = await _storage.read(key: _sessionKey);
      if (encodedSession == null) {
        return null;
      }

      final decoded = jsonDecode(encodedSession);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid stored authentication session.');
      }

      return AuthSession.fromJson(decoded);
    } on FormatException {
      throw const SessionStorageException();
    } on TypeError {
      throw const SessionStorageException();
    } on PlatformException {
      throw const SessionStorageException();
    } on MissingPluginException {
      throw const SessionStorageException();
    } on UnsupportedError {
      throw const SessionStorageException();
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    try {
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode(session.toJson()),
      );
    } on PlatformException {
      throw const SessionStorageException();
    } on MissingPluginException {
      throw const SessionStorageException();
    } on UnsupportedError {
      throw const SessionStorageException();
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _sessionKey);
    } on PlatformException {
      throw const SessionStorageException();
    } on MissingPluginException {
      throw const SessionStorageException();
    } on UnsupportedError {
      throw const SessionStorageException();
    }
  }
}
