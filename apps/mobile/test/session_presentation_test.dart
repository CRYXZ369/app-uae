import 'package:app_unificada_uae/features/auth/data/session_store.dart';
import 'package:app_unificada_uae/features/auth/model/auth_session.dart';
import 'package:app_unificada_uae/features/auth/presentation/session_expired_screen.dart';
import 'package:app_unificada_uae/features/auth/presentation/sign_out_button.dart';
import 'package:app_unificada_uae/features/auth/state/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class TestSessionStore implements SessionStore {
  AuthSession? value;
  bool failDelete = false;

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> write(AuthSession session) async => value = session;

  @override
  Future<void> delete() async {
    if (failDelete) throw StateError('Error de almacenamiento');
    value = null;
  }
}

void main() {
  testWidgets('la pantalla de sesión expirada permite volver al login', (
    tester,
  ) async {
    var navigated = false;
    await tester.pumpWidget(
      MaterialApp(home: SessionExpiredScreen(onSignIn: () => navigated = true)),
    );

    expect(find.text('Sesión expirada'), findsOneWidget);
    await tester.tap(find.text('Iniciar sesión'));
    expect(navigated, isTrue);
  });

  testWidgets('el botón borra la sesión antes de avisar que terminó', (
    tester,
  ) async {
    final store = TestSessionStore();
    final controller = SessionController(store);
    addTearDown(controller.dispose);
    await controller.save(
      AuthSession(
        accessToken: 'token-ficticio',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        roles: ['ESTUDIANTE'],
      ),
    );
    var navigated = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignOutButton(
            controller: controller,
            onSignedOut: () => navigated = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(store.value, isNull);
    expect(controller.status, SessionStatus.signedOut);
    expect(navigated, isTrue);
  });

  testWidgets('el botón informa un error sin confirmar el cierre', (
    tester,
  ) async {
    final store = TestSessionStore();
    final controller = SessionController(store);
    addTearDown(controller.dispose);
    await controller.save(
      AuthSession(
        accessToken: 'token-ficticio',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        roles: ['DOCENTE'],
      ),
    );
    store.failDelete = true;
    var navigated = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignOutButton(
            controller: controller,
            onSignedOut: () => navigated = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo cerrar la sesión. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(controller.status, SessionStatus.error);
    expect(navigated, isFalse);

    store.failDelete = false;
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(store.value, isNull);
    expect(navigated, isTrue);
  });
}
