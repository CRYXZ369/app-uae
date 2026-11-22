import 'dart:async';

import 'package:app_unificada_uae/features/auth/data/session_store.dart';
import 'package:app_unificada_uae/features/auth/model/auth_session.dart';
import 'package:app_unificada_uae/features/auth/state/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class MemorySessionStore implements SessionStore {
  AuthSession? value;
  bool failDelete = false;

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> write(AuthSession session) async => value = session;

  @override
  Future<void> delete() async {
    if (failDelete) throw StateError('No se pudo borrar la sesión.');
    value = null;
  }
}

class DelayedDeleteStore extends MemorySessionStore {
  final deleteCompleter = Completer<void>();

  @override
  Future<void> delete() async {
    await deleteCompleter.future;
    await super.delete();
  }
}

void main() {
  final now = DateTime.utc(2026, 1, 1);
  AuthSession session(List<String> roles, {String token = 'token-prueba'}) =>
      AuthSession(
        accessToken: token,
        expiresAt: now.add(const Duration(hours: 1)),
        roles: roles,
      );

  for (final role in ['ESTUDIANTE', 'DOCENTE']) {
    test('guarda y restaura sesión simulada para $role', () async {
      final store = MemorySessionStore();
      final first = SessionController(store, clock: () => now);
      addTearDown(first.dispose);
      await first.save(session([role, 'CCE']));
      final restored = SessionController(store, clock: () => now);
      addTearDown(restored.dispose);

      await restored.restore();

      expect(restored.status, SessionStatus.authenticated);
      expect((await restored.sessionForRequest())!.roles, [role, 'CCE']);
    });
  }

  test('cerrar sesión borra la sesión y no se restaura', () async {
    final store = MemorySessionStore();
    final controller = SessionController(store, clock: () => now);
    addTearDown(controller.dispose);
    await controller.save(session(['ESTUDIANTE']));

    await controller.signOut();
    await controller.restore();

    expect(store.value, isNull);
    expect(controller.status, SessionStatus.signedOut);
    expect(await controller.sessionForRequest(), isNull);
  });

  test('el cierre pendiente no muestra una sesión activa', () async {
    final store = DelayedDeleteStore();
    final controller = SessionController(store, clock: () => now);
    addTearDown(controller.dispose);
    await controller.save(session(['ESTUDIANTE']));

    final closing = controller.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(controller.status, SessionStatus.processing);
    store.deleteCompleter.complete();
    await closing;
    expect(controller.status, SessionStatus.signedOut);
  });

  test('una sesión expirada se borra antes de usarla o restaurarla', () async {
    var time = now;
    final store = MemorySessionStore();
    final controller = SessionController(store, clock: () => time);
    addTearDown(controller.dispose);
    await controller.save(session(['ESTUDIANTE']));
    time = now.add(const Duration(hours: 1));

    expect(await controller.sessionForRequest(), isNull);
    expect(controller.status, SessionStatus.expired);
    expect(store.value, isNull);

    store.value = session(['DOCENTE']);
    await controller.restore();
    expect(controller.status, SessionStatus.expired);
    expect(store.value, isNull);
  });

  testWidgets('la sesión expira aunque no se realicen solicitudes', (
    tester,
  ) async {
    var time = now;
    final store = MemorySessionStore();
    final controller = SessionController(store, clock: () => time);
    addTearDown(controller.dispose);
    await controller.save(
      AuthSession(
        accessToken: 'token-prueba',
        expiresAt: now.add(const Duration(milliseconds: 20)),
        roles: ['ESTUDIANTE'],
      ),
    );
    time = now.add(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    expect(controller.status, SessionStatus.expired);
    expect(store.value, isNull);
  });

  testWidgets('un error al borrar la sesión expirada se informa', (
    tester,
  ) async {
    var time = now;
    final store = MemorySessionStore();
    final controller = SessionController(store, clock: () => time);
    addTearDown(controller.dispose);
    await controller.save(
      AuthSession(
        accessToken: 'token-prueba',
        expiresAt: now.add(const Duration(milliseconds: 20)),
        roles: ['DOCENTE'],
      ),
    );
    store.failDelete = true;
    time = now.add(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    expect(controller.status, SessionStatus.error);
    expect(controller.error, isA<StateError>());
    expect(await controller.sessionForRequest(), isNull);
  });

  test('401 invalida la sesión actual; 403 no cierra sesión', () async {
    final store = MemorySessionStore();
    final controller = SessionController(store, clock: () => now);
    addTearDown(controller.dispose);
    await controller.save(session(['ESTUDIANTE']));

    await controller.handleHttpStatus(403, 'token-prueba');
    expect(controller.status, SessionStatus.authenticated);
    await controller.handleHttpStatus(401, 'token-anterior');
    expect(controller.status, SessionStatus.authenticated);
    await controller.handleHttpStatus(401, 'token-prueba');
    expect(controller.status, SessionStatus.expired);
    expect(store.value, isNull);
  });

  test(
    'un error al borrar se informa y no expone la sesión en memoria',
    () async {
      final store = MemorySessionStore();
      final controller = SessionController(store, clock: () => now);
      addTearDown(controller.dispose);
      await controller.save(session(['DOCENTE']));
      store.failDelete = true;

      await expectLater(controller.signOut(), throwsStateError);
      expect(controller.status, SessionStatus.error);
      expect(controller.error, isA<StateError>());
      expect(await controller.sessionForRequest(), isNull);
    },
  );

  test('rechaza una sesión ya expirada', () async {
    final controller = SessionController(
      MemorySessionStore(),
      clock: () => now,
    );
    addTearDown(controller.dispose);
    await expectLater(
      controller.save(
        AuthSession(
          accessToken: 'token-prueba',
          expiresAt: now,
          roles: ['ESTUDIANTE'],
        ),
      ),
      throwsArgumentError,
    );
  });
}
