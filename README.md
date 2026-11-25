# App Unificada UAE

Proyecto colaborativo de 5.º semestre de Ingeniería en Tecnologías de la Información de la Universidad Albert Einstein. El objetivo es construir una plataforma móvil institucional para estudiantes, docentes, trabajadores, directivos y áreas administrativas: un solo lugar para la vida académica, transporte, compras, pagos, avisos y participación universitaria.

La aplicación móvil tiene una base inicial en **Flutter** y una **API REST Java** de identidad para desarrollo local; los demás módulos y el despliegue seguro están pendientes. La persistencia objetivo es **PostgreSQL administrado por Supabase**. La aplicación Java Swing existente se conserva como legado de referencia mientras se migra la lógica al backend; no se debe agregar funcionalidad nueva allí. Para ejecutar la base móvil, consulta [su guía](apps/mobile/README.md).
<img width="1160" height="712" alt="image" src="https://github.com/user-attachments/assets/cb15fe27-3762-4d6c-aa9f-eb5941be2265" />

## Alcance del producto

- **Identidad y acceso:** correo institucional, perfiles y permisos por rol.
- **Inicio personalizado:** materias, asistencia, pendientes, avisos y accesos rápidos.
- **Académico:** horarios por carrera/grupo, materias, tareas, progreso y calificación estimada.
- **Transporte:** cuatro rutas configurables, paradas, horarios, ubicación en tiempo real y confirmación de salidas extraordinarias.
- **Compras:** prototipo de pedidos para Cafetería Arriba y Cafetería Abajo, descuentos estudiantiles y futura integración de venta.
- **Pagos y documentos:** mensualidades, servicios, comprobantes y seguimiento de constancias.
- **Comunidad:** avisos oficiales, marketing, CCE, encuestas y votaciones.

La información de rutas, montos, horarios y políticas debe validarse con la universidad antes de considerarse oficial.

## Inicio rápido (presentación en navegador local)

Requiere `services/api-java/.env` configurado con la base de datos.

**Opción recomendada (1 sola terminal):**

```sh
cd /home/CRYXZ/app-uae && ./iniciar-presentacion.sh
```

**Opción manual (2 terminales en una sola línea cada una):**

**Terminal 1 — API Java (puerto 8080):**

```sh
cd /home/CRYXZ/app-uae && set -a && source services/api-java/.env && set +a && export DEV_WEB_ORIGINS=http://127.0.0.1:8081,http://localhost:8081 && cd services/api-java && mvn spring-boot:run
```

**Terminal 2 — Flutter Web (puerto 8081):**

```sh
cd /home/CRYXZ/app-uae/apps/mobile && flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8081 --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Una vez que ambos servicios estén corriendo, abre `http://127.0.0.1:8081` en tu navegador (usa `F12` + `Ctrl + Shift + M` para activar el modo de vista móvil). Consulta [apps/mobile/README.md](apps/mobile/README.md) para pruebas en teléfonos por red Wi-Fi.

## Estructura del monorepo

```text
apps/mobile/                         Aplicación Flutter para Android/iOS
services/api-java/                   API REST Java (destino de la migración)
services/desktop-legacy/backend-java/Cliente Java Swing/JDBC legado
database/                            Esquema, migraciones y datos de desarrollo
docs/                                Arquitectura, módulos, roles y operación del equipo
hardware-bomba/                      Prototipo físico independiente
```

Consulta primero:

1. `docs/00-justificacion-del-proyecto.md`
2. `docs/01-arquitectura-repositorio.md`
3. `docs/02-modulos-y-mvp.md`
4. `docs/03-guia-del-equipo.md`
5. `docs/kanban.md`
6. `docs/roles-y-permisos.md`
7. `docs/sincronizacion-equipo.md`
8. [Kanban en Trello](https://trello.com/invite/b/6abfddaef626f8ca41f4136f/ATTI8765e7c5599da8e4c2f78df7b85e6d88D89035AB/mi-tablero-de-trello)

La documentación complementaria del equipo está en la carpeta compartida de [Google Drive](https://drive.google.com/drive/folders/1JWi4O-No4db1N4jgEwp1JrdOCgdOGl7k?usp=sharing).

## Reglas importantes

- No subir contraseñas, tokens, datos reales de alumnos ni archivos `.env`.
- Toda funcionalidad debe tener responsable, criterios de aceptación y prueba.
- Los cambios de base de datos se agregan como migración nueva; no se edita una migración ya compartida.
- El backend es la autoridad para permisos, pagos, votos y estados; Flutter nunca debe confiar solo en validaciones visuales.
- Los datos de transporte en tiempo real son informativos y no sustituyen los canales oficiales.

## Base de datos PostgreSQL / Supabase

Supabase utiliza PostgreSQL. Para una instalación nueva o para completar el esquema existente, aplica en este orden desde el SQL Editor de Supabase o con `psql`:

1. `database/01_ddl_app_unificada_uae_postgres.sql`
2. `database/02_ddl_compatibilidad_supabase.sql` — conserva `clave`, `codigo_grupo` y `semestre`, y mantiene sus alias sincronizados con el modelo de la app.
3. `database/03_ddl_academico_postgres.sql`
4. `database/04_dml_academico_demo_postgres.sql`
5. `database/05_ddl_tareas_academicas_postgres.sql`
6. `database/06_dml_tareas_demo_postgres.sql`
7. `database/07_ddl_calificaciones_academicas_postgres.sql`
8. `database/08_dml_calificaciones_demo_postgres.sql`
9. `database/09_ddl_sesiones_identidad_postgres.sql`
10. `database/10_ddl_asistencia_academica_postgres.sql`
11. `database/11_dml_asistencia_demo_postgres.sql`

Las migraciones son acumulativas; no edites las ya aplicadas. `02`, `04`, `08` y `09` son repetibles. Usa una base de desarrollo y conserva un respaldo antes de aplicarlas. Si `database/07_ddl_sesiones_identidad_postgres.sql` ya se aplicó en una base, no vuelvas a ejecutarla; `09` es su versión idempotente con numeración consolidada.

`database/01_ddl_app_unificada_uae.sql` es el esquema histórico de MySQL y se conserva únicamente como referencia del prototipo anterior. Los datos de desarrollo deben adaptarse a PostgreSQL antes de ejecutarse. No use credenciales de administrador ni publique claves de Supabase.

## Cliente legado Java

Requisitos: JDK 17, Maven, PostgreSQL/Supabase accesible y entorno gráfico. Este cliente solo conserva el prototipo actual durante la migración:

```sh
cd services/desktop-legacy/backend-java
mvn package dependency:copy-dependencies
export DB_URL='jdbc:postgresql://HOST:5432/postgres?sslmode=require'
export DB_USER='su_usuario'
read -rs -p 'Contraseña de base de datos: ' DB_PASSWORD; echo
export DB_PASSWORD
java -cp 'target/classes:target/dependency/*' mx.edu.uae.app.view.LoginFrame
```

Java lee las variables del entorno y **no carga archivos `.env` automáticamente**. Nunca publique credenciales ni contraseñas en texto plano.

## Contribución

La asignación de trabajo, el flujo de ramas, las revisiones y el procedimiento para cada integrante están en `docs/03-guia-del-equipo.md`. El trabajo pendiente priorizado está en `docs/kanban.md`.
