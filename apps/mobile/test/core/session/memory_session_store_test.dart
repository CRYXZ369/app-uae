import 'package:app_unificada_uae/core/session/memory_session_store.dart';
import 'package:app_unificada_uae/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guarda la sesión solo en memoria y la elimina al limpiar', () async {
    final store = MemorySessionStore();
    final session = AuthSession(
      accessToken: 'token-demo',
      email: 'alumno@uae.edu.mx',
      expiresAt: DateTime.utc(2099),
      roles: const ['ESTUDIANTE'],
    );

    expect(await store.read(), isNull);
    await store.write(session);
    expect((await store.read())?.accessToken, 'token-demo');
    await store.clear();
    expect(await store.read(), isNull);
  });
}
