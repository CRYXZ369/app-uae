import 'dart:convert';

import 'package:app_unificada_uae/features/auth/data/identity_api.dart';
import 'package:app_unificada_uae/features/auth/presentation/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('inicia sesión y lee el token devuelto por la API', () async {
    final api = IdentityApi(
      'http://127.0.0.1:8080',
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/sessions');
        expect(jsonDecode(request.body), {
          'email': 'alumno@uae.edu.mx',
          'password': 'prueba',
        });
        return http.Response(
          jsonEncode({
            'accessToken': 'token-ficticio',
            'email': 'alumno@uae.edu.mx',
            'expiresAt': '2099-01-01T00:00:00Z',
            'roles': ['ESTUDIANTE'],
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final result = await api.login('alumno@uae.edu.mx', 'prueba');
    expect(result.status, LoginStatus.authenticated);
    expect(result.session?.accessToken, 'token-ficticio');
  });

  test('distingue credenciales inválidas de fallos de servicio', () async {
    var status = 401;
    final api = IdentityApi(
      'https://api.ejemplo.edu',
      client: MockClient((_) async => http.Response('', status)),
    );
    addTearDown(api.close);
    expect((await api.login('a', 'b')).status, LoginStatus.invalidCredentials);
    status = 500;
    expect((await api.login('a', 'b')).status, LoginStatus.unavailable);
    status = 200;
    expect((await api.login('a', 'b')).status, LoginStatus.unavailable);
  });

  test('verifica y revoca con el token, sin ocultar fallos', () async {
    var status = 200;
    final api = IdentityApi(
      'http://localhost:8080',
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token-ficticio');
        return http.Response('', status);
      }),
    );
    addTearDown(api.close);
    expect(await api.isSessionValid('token-ficticio'), isTrue);
    status = 401;
    expect(await api.isSessionValid('token-ficticio'), isFalse);
    status = 204;
    await api.revoke('token-ficticio');
    status = 500;
    await expectLater(
      api.revoke('token-ficticio'),
      throwsA(isA<IdentityApiException>()),
    );
  });

  test('rechaza HTTP remoto y direcciones mal configuradas', () {
    expect(() => IdentityApi('http://api.ejemplo.edu'), throwsArgumentError);
    expect(
      () => IdentityApi('https://api.ejemplo.edu/subruta'),
      throwsArgumentError,
    );
  });
}
