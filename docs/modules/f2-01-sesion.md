# F2-01 — Inicio de sesión: sesión y pruebas

## Alcance

El formulario de Donovan está conectado a una API de identidad local de
desarrollo. No conectar Flutter directamente a PostgreSQL ni incluir
credenciales en la app. La API aún no está lista para producción; consultar su
[guía](../../services/api-java/README.md).

## Checklist de CRYXZ, en orden

1. **Guardar sesión de forma segura — implementado localmente.** Se guarda el
   token y vencimiento con `flutter_secure_storage`; faltan pruebas reales en
   dispositivos Android/iOS.
2. **Cerrar sesión — implementado.** La app revoca el token en la API y borra
   el almacenamiento local; si falla, informa y permite reintentar.
3. **Manejar sesión expirada — implementado para identidad.** La app detecta
   expiración local y verifica la sesión al restaurarla. La API rechaza tokens
   expirados o revocados. Falta integrar este manejo con futuros endpoints.
4. **Probar alumno — integración automatizada con datos ficticios.** Se probó
   login y consulta de roles contra PostgreSQL temporal; falta probar el flujo
   en dispositivos con cuentas autorizadas de desarrollo.
5. **Probar docente — integración automatizada con datos ficticios.** Mismo
   alcance y pendientes que alumno.
6. **Probar usuario no autorizado — parcial.** Se prueba el rechazo de
   credenciales y sesiones inválidas. Faltan endpoints de recursos y pruebas
   de denegación 403 por permisos.

No marcar la tarjeta como terminada hasta completar pruebas en dispositivos,
autorización por recurso, revisión de seguridad y revisión del equipo.

## Integración y pruebas

La app usa `API_BASE_URL` para localizar la API; el contrato, las migraciones
y los límites del prototipo se explican en la guía de la API. Desde
`apps/mobile`, ejecutar `flutter analyze` y `flutter test`. Las pruebas de
servidor se ejecutan con Maven; las de base de datos requieren una base
exclusiva de pruebas. Nunca publicar credenciales ni tokens.
