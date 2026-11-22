# F2-01 — Inicio de sesión: sesión y pruebas

## Alcance y dependencias

El formulario de Donovan ya está integrado. La API REST de identidad aún no
está implementada: los datos de conexión PostgreSQL no son endpoints de
autenticación. No conectar Flutter directamente a la base de datos ni incluir
credenciales en la app. Faltan el contrato de identidad (F1-04), la API
(F1-02) y usuarios de prueba autorizados para verificar el flujo completo.

## Checklist de CRYXZ, en orden

1. **Guardar sesión de forma segura — implementación local.**
   `SecureSessionStore` guarda tokens, correo y vencimiento con
   `flutter_secure_storage`; no guarda contraseñas. Faltan integrar la respuesta
   real de la API y verificar Android/iOS en dispositivos.
2. **Cerrar sesión — implementación local.** La pantalla inicial elimina la
   sesión del dispositivo y vuelve al formulario. Falta revocar la sesión en
   el servidor: borrar el token local no lo invalida en el servidor.
3. **Manejar sesión expirada — implementación local.** Se descartan sesiones
   vencidas al restaurar y durante el uso; se muestra la pantalla de expiración
   para volver al formulario. Falta integrar las respuestas de la API,
   incluyendo 401, y definir la renovación de tokens.
4. **Probar alumno — pendiente de API.** La prueba automatizada usa una sesión
   ficticia con correo de alumno, pero no verifica roles ni permisos reales.
5. **Probar docente — pendiente de API.** Se prueba con datos ficticios un
   error de borrado de sesión; falta autenticar y comprobar permisos de docente.
6. **Probar usuario no autorizado — pendiente de API.** Falta verificar que el
   servidor rechace credenciales y deniegue recursos protegidos sin permiso.

No marcar la tarjeta como terminada hasta completar integración, pruebas reales
de rol y revisión del equipo.

## Guía de integración

- Conectar `LoginHandler` a la API cuando se defina su contrato; nunca asignar
  tokens ni roles inventados en producción. La fecha de expiración debe venir
  del servidor.
- Integrar el cierre con la revocación del servidor; limpiar la navegación
  protegida. Los permisos deben comprobarse en el backend.
- Gestionar las respuestas 401 y los 403 según el contrato de la API, sin
  tratar un 403 de autorización como inicio de sesión exitoso.
- Las pruebas automatizadas simulan almacenamiento y autenticación; no
  demuestran la seguridad de Keychain o Android Keystore. Verificar ambos en
  dispositivos y recopilar evidencia sin publicar contraseñas ni tokens.

## Pruebas ejecutables

Desde `apps/mobile`:

```sh
flutter analyze
flutter test
```
