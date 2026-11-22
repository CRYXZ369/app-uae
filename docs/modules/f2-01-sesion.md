# F2-01 — Inicio de sesión: sesión y pruebas

## Alcance y dependencias

La pantalla de correo y contraseña, sus validaciones y estados son trabajo
paralelo de Donovan. La API REST de identidad aún no está implementada: los
datos de conexión PostgreSQL no son endpoints de autenticación. No conectar
Flutter directamente a la base de datos ni incluir credenciales en la app.
Faltan el contrato de identidad (F1-04), la API (F1-02) y usuarios de prueba
autorizados antes de verificar el flujo completo.

## Checklist de CRYXZ, en orden

1. **Guardar sesión de forma segura — base implementada.**
   `SecureSessionStore` guarda token, fecha de expiración y roles con
   `flutter_secure_storage` en Android/iOS; no guarda contraseñas. La integración
   con la respuesta real del servidor y las pruebas en dispositivos faltan.
2. **Cerrar sesión — base local implementada.** `signOut()` elimina la sesión
   local y `SignOutButton` permite ejecutarlo e informa errores. Falta integrar
   el botón y la navegación, además de revocar la sesión en el servidor: borrar
   el token del dispositivo no revoca por sí solo un token válido.
3. **Manejar sesión expirada — base implementada.** Se verifica al restaurar,
   antes de una solicitud y mediante temporizador; un HTTP 401 de la sesión
   actual también la invalida. `SessionExpiredScreen` permite avisar y volver
   al inicio de sesión; faltan conexión HTTP e integración de navegación.
4. **Probar alumno — prueba simulada.** Prueba automatizada de persistencia y
   restauración con rol `ESTUDIANTE`; falta probar una cuenta real de desarrollo
   y sus permisos en la API.
5. **Probar docente — prueba simulada.** Prueba equivalente con `DOCENTE`;
   falta probar una cuenta real de desarrollo y sus permisos en la API.
6. **Probar usuario no autorizado — prueba simulada parcial.** Se comprueba
   que un 401 invalida la sesión y un 403 no la cierra. Falta demostrar con la
   API que una cuenta sin permiso recibe 403 y no accede al recurso protegido.

No marcar la tarjeta como terminada hasta completar integración, pruebas reales
de rol y revisión del equipo.

## Guía de integración

- Crear una instancia compartida de `SessionController(SecureSessionStore())`.
  Llamar a `restore()` al arrancar y mostrar carga hasta que termine.
- Tras un inicio de sesión aceptado por la API, construir `AuthSession` con el
  token, expiración absoluta y todos los roles devueltos por el servidor, y
  esperar `save()`. El modelo es provisional: adaptar los campos al contrato
  real, sin inventar tokens ni asignar roles en el cliente.
- Antes de cada solicitud protegida, esperar `sessionForRequest()`; no enviar
  credenciales si devuelve `null`. Al recibir una respuesta, pasar su código y
  el token usado a `handleHttpStatus()`. Un 401 antiguo no debe cerrar otra
  sesión; un 403 se presenta como falta de permiso sin cerrar la sesión.
- Observar `status`: `processing` requiere mostrar carga, `expired` requiere
  reingreso y `error` requiere mostrar un error y permitir recuperación.
  Las operaciones también propagan errores.
  Si falla el borrado, no afirmar que se cerró sesión ni que fue revocada.
- Conectar `signOut()` al botón y a la revocación del servidor cuando exista;
  limpiar la navegación protegida. Los roles del cliente son informativos:
  cada recurso debe comprobar autorización en el backend.
- `SignOutButton` realiza solo el borrado local y llama a `onSignedOut` al
  terminar; `SessionExpiredScreen` llama a `onSignIn` para abrir el formulario.
  Ambos son componentes independientes y aún no están conectados a la app.
  Antes de publicar el flujo, integrar el cierre en el servidor.
- La persistencia solo está habilitada para Android e iOS. Probar Keychain y
  Android Keystore en dispositivos; las pruebas unitarias usan almacenamiento
  simulado y no demuestran seguridad de la plataforma.

## Pruebas ejecutables

Desde `apps/mobile`:

```sh
flutter test test/session_controller_test.dart test/session_store_test.dart test/session_presentation_test.dart
flutter analyze
```

Para cerrar la tarjeta, añadir evidencia de inicio/cierre, restauración,
expiración y denegación de acceso usando cuentas ficticias y la API real, sin
publicar contraseñas ni tokens.
