# App Unificada UAE

Proyecto universitario de 5.º semestre de Ingeniería en Tecnologías de la Información de la Universidad Albert Einstein. Su propósito es reunir en una aplicación de escritorio la información y los servicios cotidianos de estudiantes, docentes y personal: cafetería, horarios, transporte, avisos de salud, anuncios y votaciones del CCE y encuestas.

Esta primera etapa proporciona el esquema de datos y una base Java Swing/JDBC. El inicio de sesión y los DAO de consulta de cafetería y votaciones son ejemplos funcionales; el panel y los demás módulos aún están en desarrollo. No es un sistema listo para producción ni sustituye los canales oficiales de emergencia.

## Estructura

```text
database/         Esquema MySQL/MariaDB y plantilla de datos
backend-java/     Aplicación Java 17: configuración, modelos, DAO y vistas Swing
hardware-bomba/   Documentación y firmware pendiente del juego físico
```

El esquema separa las paradas de las rutas y las opciones de las votaciones; las claves foráneas relacionan los módulos y evitan asignar a una votación una opción de otra. Los precios de los detalles de pedido son históricos. Los votos quedan asociados a los usuarios: este diseño no garantiza anonimato.

## Base de datos

Se requiere MySQL 8.0.16 o posterior o MariaDB 10.5 o posterior, con soporte de restricciones `CHECK`. El script crea la base `app_unificada_uae`; ejecútelo una sola vez sobre una instalación vacía. Para volver a ejecutarlo en desarrollo, elimine previamente la base **solo si está seguro de perder todos sus datos**.

En DBeaver, cree una conexión al servidor con una cuenta autorizada para crear bases y tablas, abra `database/01_ddl_app_unificada_uae.sql` en el editor SQL y ejecute el script completo (no solo la sentencia seleccionada). Después abra `database/02_dml_datos_prueba.sql` y adapte sus ejemplos comentados. También puede usar el cliente:

```sh
mysql -u administrador -p < database/01_ddl_app_unificada_uae.sql
mysql -u administrador -p < database/02_dml_datos_prueba.sql
```

Los ejemplos son una plantilla y no crean usuarios automáticamente. Cree por separado una cuenta de base de datos para la aplicación con los permisos mínimos necesarios sobre esta base, sin usar la cuenta administradora para ejecutar el cliente.

## Aplicación Java

Requisitos: JDK 17, Maven, MySQL accesible y entorno gráfico. El conector Maven incluido es MySQL Connector/J; la conexión de ejemplo está dirigida a MySQL. Desde la raíz:

```sh
cd backend-java
mvn package dependency:copy-dependencies
export DB_URL='jdbc:mysql://localhost:3306/app_unificada_uae'
export DB_USER='su_usuario'
read -rs -p 'Contraseña de base de datos: ' DB_PASSWORD; echo
export DB_PASSWORD
java -cp 'target/classes:target/dependency/*' mx.edu.uae.app.view.LoginFrame
```

En Windows sustituya `:` por `;` en el classpath y configure las variables según su terminal. `backend-java/.env.example` documenta los nombres de las variables; Java las lee del entorno y **no carga archivos `.env` automáticamente**. No publique credenciales; para conexiones remotas configure TLS y la verificación del servidor según la documentación del conector.

Para crear un usuario de prueba, genere un hash usando `PasswordHasher.hash(char[])`, que produce `pbkdf2_sha256$iteraciones$sal_base64$hash_base64` con sal aleatoria. Después de compilar, en una terminal interactiva ejecute:

```sh
java -cp target/classes mx.edu.uae.app.config.PasswordHasher
```

Escriba la contraseña cuando se solicite y copie únicamente el hash generado al campo `password_hash` del ejemplo SQL. Use un correo `@uae.edu.mx` y nunca guarde contraseñas en texto plano. El alta de usuarios y la gestión de permisos todavía deben implementarse antes de un despliegue real.

## Contribución

1. Cristian, Enrique, Donovan, Camila y Carlos: acuerden la tarea y trabajen en una rama por cambio.
2. Mantengan separados el esquema, la aplicación y el prototipo físico; documenten los cambios de configuración y las migraciones de datos.
3. Compilen con `mvn package` desde `backend-java` y prueben los scripts SQL en una base de desarrollo antes de solicitar revisión.
4. Abran una solicitud de cambios con una descripción y los pasos de prueba; soliciten revisión de otro integrante. No incluyan credenciales, datos reales, archivos generados ni dependencias descargadas.
