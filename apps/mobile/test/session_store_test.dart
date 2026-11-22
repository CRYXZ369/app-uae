import 'package:app_unificada_uae/features/auth/data/session_store.dart';
import 'package:app_unificada_uae/features/auth/model/auth_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('escribe, lee y elimina una sesión en el almacenamiento', () async {
    final store = SecureSessionStore();
    final session = AuthSession(
      accessToken: 'token-ficticio',
      expiresAt: DateTime.utc(2030),
      roles: ['ESTUDIANTE', 'CCE'],
    );

    await store.write(session);
    final restored = await store.read();
    expect(restored?.accessToken, session.accessToken);
    expect(restored?.expiresAt, session.expiresAt);
    expect(restored?.roles, session.roles);
    await store.delete();
    expect(await store.read(), isNull);
  });

  test('rechaza datos de sesión corruptos', () async {
    FlutterSecureStorage.setMockInitialValues({'auth_session': '{"roles":[]}'});
    await expectLater(SecureSessionStore().read(), throwsFormatException);
  });

  test('no habilita persistencia en plataformas no soportadas', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await expectLater(SecureSessionStore().read(), throwsUnsupportedError);
  });
}
