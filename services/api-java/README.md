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
2. Crear la configuración local sin subir secretos al repositorio:

   ```sh
   cp services/api-java/.env.example services/api-java/.env
   ```

   Editar `.env` con el host, puerto, usuario y contraseña de la base de
   desarrollo. Para Supabase, descargar el certificado CA desde Database
   Settings → SSL Configuration y guardarlo como `~/.postgresql/root.crt`;
   usar `sslmode=verify-full` en `DB_URL`. La API no carga `.env`
   automáticamente, así que al iniciar desde la raíz exporta sus variables:

   ```sh
   set -a
   source services/api-java/.env
   set +a
   export DEV_WEB_ORIGINS=http://127.0.0.1:8081,http://localhost:8081
   cd services/api-java
   mvn spring-boot:run
   ```

   `.env` está excluido de Git. No publicar credenciales ni datos de usuarios.
   `SERVER_PORT` es opcional y por defecto usa 8080.
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

Para navegador local, configurar `DEV_WEB_ORIGIN` (o varios orígenes separados
por comas en `DEV_WEB_ORIGINS`) con el origen exacto del navegador. Se aceptan
localhost y orígenes HTTP con IP privada para pruebas en una red local; no se
habilita CORS por defecto. El servidor escucha solo en `127.0.0.1` por defecto.
Para la demo entre teléfonos, establecer `SERVER_ADDRESS` a la IP Wi-Fi de la
laptop y usar `LAN_DEMO_MODE=true` únicamente al iniciar Flutter web. Esto es
para desarrollo local, no para desplegar la API en Internet.

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
