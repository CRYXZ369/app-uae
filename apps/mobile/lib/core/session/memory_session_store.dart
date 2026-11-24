import '../../features/auth/domain/auth_session.dart';
import 'session_store.dart';

/// Session storage for local, insecure-LAN browser demos only.
///
/// The session exists only in this process and disappears when the page reloads
/// or closes. Normal app builds continue to use encrypted platform storage.
class MemorySessionStore implements SessionStore {
  AuthSession? _session;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}
