import 'dart:async';
import 'dart:convert';

import 'package:app_unificada_uae/app/app.dart';
import 'package:app_unificada_uae/core/session/session_store.dart';
import 'package:app_unificada_uae/core/widgets/app_error_screen.dart';
import 'package:app_unificada_uae/core/widgets/app_loading_screen.dart';
import 'package:app_unificada_uae/features/auth/domain/auth_session.dart';
import 'package:app_unificada_uae/features/auth/data/identity_api.dart';
import 'package:app_unificada_uae/features/auth/presentation/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

final _testSession = AuthSession(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  email: 'alumno@uae.edu.mx',
  expiresAt: DateTime.utc(2099),
);

void main() {
  test('la sesión persiste tokens y no incluye contraseñas', () {
    final serialized = _testSession.toJson();
    final restored = AuthSession.fromJson(serialized);

    expect(serialized['accessToken'], _testSession.accessToken);
    expect(serialized['refreshToken'], _testSession.refreshToken);
    expect(serialized.containsKey('password'), isFalse);
    expect(restored.email, _testSession.email);
  });

  testWidgets('muestra el formulario de inicio de sesión', (tester) async {
    await tester.pumpWidget(AppUae(sessionStore: FakeSessionStore()));
    await tester.pumpAndSettle();

    expect(find.text('App Unificada UAE'), findsOneWidget);
    expect(find.text('Correo institucional'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('valida formato de correo y campos requeridos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (_, _) async => LoginResult.authenticated(_testSession),
        ),
      ),
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresa tu correo institucional.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'correo-invalido',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secreto',
    );
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresa un correo con formato válido.'), findsOneWidget);
  });

  testWidgets('permite mostrar y ocultar la contraseña', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (_, _) async => LoginResult.authenticated(_testSession),
        ),
      ),
    );

    final passwordField = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Contraseña'),
        matching: find.byType(TextField),
      ),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();

    final visiblePasswordField = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Contraseña'),
        matching: find.byType(TextField),
      ),
    );
    expect(visiblePasswordField.obscureText, isFalse);
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });

  testWidgets('muestra carga durante la autenticación', (tester) async {
    final completer = Completer<LoginResult>();
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onLogin: (_, _) => completer.future)),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'alumno@uae.edu.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secreto',
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Iniciando sesión...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    completer.complete(const LoginResult.unavailable());
    await tester.pumpAndSettle();
  });

  testWidgets('muestra error cuando el servicio rechaza las credenciales', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (_, _) async => const LoginResult.invalidCredentials(),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'alumno@uae.edu.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'incorrecta',
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(
      find.text('El correo o la contraseña son incorrectos.'),
      findsOneWidget,
    );
  });

  testWidgets('guarda sesión y abre el inicio tras autenticar', (tester) async {
    final sessionStore = FakeSessionStore();
    await tester.pumpWidget(
      AppUae(
        sessionStore: sessionStore,
        onLogin: (_, _) async => LoginResult.authenticated(_testSession),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'alumno@uae.edu.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secreto',
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(sessionStore.session?.accessToken, _testSession.accessToken);
    expect(find.text('La aplicación está en desarrollo.'), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(sessionStore.session, isNull);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('conecta login y cierre a la API', (tester) async {
    final requests = <String>[];
    final api = IdentityApi(
      'http://localhost:8080',
      client: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/revoke')) {
          expect(request.headers['Authorization'], 'Bearer access-token');
          return http.Response('', 204);
        }
        return http.Response(jsonEncode(_testSession.toJson()), 200);
      }),
    );
    addTearDown(api.close);
    final store = FakeSessionStore();
    await tester.pumpWidget(AppUae(sessionStore: store, identityApi: api));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'alumno@uae.edu.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'ficticia',
    );
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(store.session?.accessToken, 'access-token');
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(store.session, isNull);
    expect(requests, [
      'POST /api/v1/sessions',
      'POST /api/v1/sessions/current/revoke',
    ]);
  });

  testWidgets('una sesión revocada se descarta al restaurar', (tester) async {
    final api = IdentityApi(
      'http://localhost:8080',
      client: MockClient((_) async => http.Response('', 401)),
    );
    addTearDown(api.close);
    final store = FakeSessionStore(_testSession);
    await tester.pumpWidget(AppUae(sessionStore: store, identityApi: api));
    await tester.pumpAndSettle();
    expect(store.session, isNull);
    expect(find.text('Sesión expirada'), findsOneWidget);
  });

  testWidgets('restaura la sesión guardada al iniciar', (tester) async {
    await tester.pumpWidget(
      AppUae(sessionStore: FakeSessionStore(_testSession)),
    );
    await tester.pumpAndSettle();

    expect(find.text('La aplicación está en desarrollo.'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('elimina y no restaura una sesión expirada', (tester) async {
    final store = FakeSessionStore(
      AuthSession(
        accessToken: 'expired-token',
        email: 'alumno@uae.edu.mx',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
    await tester.pumpWidget(AppUae(sessionStore: store));
    await tester.pumpAndSettle();

    expect(store.session, isNull);
    expect(store.didClear, isTrue);
    expect(find.text('Sesión expirada'), findsOneWidget);
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('una sesión activa expira y vuelve al formulario', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 1, 1);
    final store = FakeSessionStore(
      AuthSession(
        accessToken: 'token-ficticio',
        email: 'alumno@ejemplo.edu',
        expiresAt: now.add(const Duration(seconds: 5)),
      ),
    );
    await tester.pumpWidget(AppUae(sessionStore: store, clock: () => now));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);

    now = now.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(store.session, isNull);
    expect(find.text('Sesión expirada'), findsOneWidget);
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Correo institucional'), findsOneWidget);
  });

  testWidgets(
    'si falla el borrado de una sesión expirada se permite reintentar',
    (tester) async {
      final store = FakeSessionStore(
        AuthSession(
          accessToken: 'token-ficticio',
          email: 'docente@ejemplo.edu',
          expiresAt: DateTime.utc(2020),
        ),
      )..failClears = true;
      await tester.pumpWidget(AppUae(sessionStore: store));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo recuperar la sesión'), findsOneWidget);
      store.failClears = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(store.session, isNull);
      expect(find.text('Sesión expirada'), findsOneWidget);
    },
  );

  testWidgets('muestra error si falla la lectura del almacenamiento seguro', (
    tester,
  ) async {
    final store = FakeSessionStore()..failReads = true;
    await tester.pumpWidget(AppUae(sessionStore: store));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo recuperar la sesión'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('muestra error y no entra si no puede guardar la sesión', (
    tester,
  ) async {
    final store = FakeSessionStore()..failWrites = true;
    await tester.pumpWidget(
      AppUae(
        sessionStore: store,
        onLogin: (_, _) async => LoginResult.authenticated(_testSession),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'alumno@uae.edu.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secreto',
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo guardar la sesión de forma segura.'),
      findsOneWidget,
    );
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('mantiene la sesión visible si falla el borrado seguro', (
    tester,
  ) async {
    final store = FakeSessionStore(_testSession)..failClears = true;
    await tester.pumpWidget(AppUae(sessionStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(
      find.text(
        'No se pudo cerrar la sesión en el servicio o en el dispositivo. Inténtalo de nuevo.',
      ),
      findsOneWidget,
    );
    expect(store.session?.accessToken, _testSession.accessToken);
  });

  testWidgets('indica que falta conectar el servicio de autenticación', (
    tester,
  ) async {
    await tester.pumpWidget(AppUae(sessionStore: FakeSessionStore()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo institucional'),
      'alumno@uae.edu.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secreto',
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo conectar al servicio de inicio de sesión.'),
      findsOneWidget,
    );
  });

  testWidgets('muestra una pantalla de carga con su mensaje', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppLoadingScreen(message: 'Cargando datos')),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando datos'), findsOneWidget);
  });

  testWidgets('muestra error para rutas no registradas', (tester) async {
    await tester.pumpWidget(AppUae(sessionStore: FakeSessionStore()));
    await tester.pumpAndSettle();
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed<void>('/ruta-inexistente'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pantalla no encontrada'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('la acción de error vuelve al formulario', (tester) async {
    await tester.pumpWidget(AppUae(sessionStore: FakeSessionStore()));
    await tester.pumpAndSettle();
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed<void>('/ruta-inexistente'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('la pantalla de error muestra el mensaje recibido', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppErrorScreen(message: 'No fue posible completar la solicitud.'),
      ),
    );

    expect(find.text('Ocurrió un error'), findsOneWidget);
    expect(find.text('No fue posible completar la solicitud.'), findsOneWidget);
  });
}

class FakeSessionStore implements SessionStore {
  FakeSessionStore([this.session]);

  AuthSession? session;
  bool didClear = false;
  bool failReads = false;
  bool failWrites = false;
  bool failClears = false;

  @override
  Future<AuthSession?> read() async {
    if (failReads) {
      throw const SessionStorageException();
    }
    return session;
  }

  @override
  Future<void> write(AuthSession session) async {
    if (failWrites) {
      throw const SessionStorageException();
    }
    this.session = session;
  }

  @override
  Future<void> clear() async {
    if (failClears) {
      throw const SessionStorageException();
    }
    didClear = true;
    session = null;
  }
}
