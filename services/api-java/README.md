# API Java de identidad (desarrollo)

API Java 17 y Maven con PostgreSQL. Este es un prototipo local, **no listo
para producción**: escucha únicamente en `127.0.0.1`, no ofrece HTTPS y su
límite de intentos está en memoria por proceso. Antes de exponerlo se requieren
revisión de seguridad, TLS, protección contra ataques distribuidos, limpieza
de sesiones vencidas, observabilidad y política institucional de usuarios.

## Preparación

1. Usar una base PostgreSQL **de desarrollo** y respaldarla. Para el esquema
   completo, aplica las migraciones `database/01` a `database/09` en el orden
   indicado en el README raíz. Para probar solo identidad, aplica
   `database/01_ddl_app_unificada_uae_postgres.sql` y después
   `database/09_ddl_sesiones_identidad_postgres.sql`. La migración crea un
   índice único normalizado para el correo; si hay duplicados que solo
   difieren en mayúsculas, resolverlos antes de aplicarla. No ejecutarla sin autorización en una base
   compartida o de producción. La tabla de sesiones activa RLS sin políticas
   públicas; el rol de conexión de la API necesita acceso autorizado a ella.
2. Configurar `DB_URL`, `DB_USER` y `DB_PASSWORD` como variables del entorno,
   y opcionalmente `SERVER_PORT` (por defecto 8080). La API no lee `.env`
   automáticamente. Para una base remota, `DB_URL` debe incluir
   `?sslmode=verify-full` y Java/PostgreSQL debe confiar en su CA.
   No publicar el archivo `.env`, credenciales ni datos de usuarios.
3. Las cuentas deben tener el hash `pbkdf2_sha256` compatible con
   `PasswordHasher` del cliente legado y roles en `roles`/`usuario_roles`.
   No se crean cuentas ni contraseñas automáticamente. Usar cuentas ficticias
   en desarrollo y no pegar contraseñas o hashes en el repositorio.
4. Ejecutar:

   ```sh
   cd services/api-java
   mvn test
   mvn spring-boot:run
   ```

Para navegador local, configurar opcionalmente `DEV_WEB_ORIGIN` como un origen
exacto como `http://localhost:8081` y ejecutar Flutter en ese mismo origen.
Solo se aceptan orígenes localhost; no se habilita CORS por defecto.

## Contrato de identidad

Todos los errores devuelven un código seguro; no registrar claves ni tokens.

| Método y ruta | Función |
|---|---|
| `POST /api/v1/sessions` | JSON `email`, `password`; devuelve `accessToken`, `email`, `expiresAt` UTC y `roles`. Credenciales incorrectas: 401. |
| `GET /api/v1/sessions/current` | Requiere `Authorization: Bearer <token>`; devuelve correo y roles o 401 para sesión inválida/vencida. |
| `POST /api/v1/sessions/current/revoke` | Con Bearer, borra la sesión del servidor; responde 204. |

El token es aleatorio, expira en una hora y solo se conserva su SHA-256 en la
base. Se limitan a diez intentos por minuto por dirección en este proceso
local; 429 indica límite excedido. La app no debe deducir permisos de su propia
interfaz: cada endpoint protegido debe verificarlos en la API.

## Pruebas

`mvn test` ejecuta pruebas unitarias. La prueba de integración requiere una
base **exclusiva de pruebas**, con las migraciones 01 y 09 aplicadas:

```sh
RUN_IDENTITY_DB_TESTS=true mvn test
```

Las pruebas usan las variables de conexión anteriores y crean usuarios
ficticios: una revierte su transacción y otra elimina su usuario al terminar.
No usar la base compartida para ellas.
