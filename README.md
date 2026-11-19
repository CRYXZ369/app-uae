# App Unificada UAE

Proyecto colaborativo de 5.º semestre de Ingeniería en Tecnologías de la Información de la Universidad Albert Einstein. El objetivo es construir una plataforma móvil institucional para estudiantes, docentes, trabajadores, directivos y áreas administrativas: un solo lugar para la vida académica, transporte, compras, pagos, avisos y participación universitaria.

La aplicación móvil se construirá con **Flutter** y consumirá una **API REST Java**. La persistencia objetivo es **PostgreSQL administrado por Supabase**. La aplicación Java Swing existente se conserva como legado de referencia mientras se migra la lógica al backend; no se debe agregar funcionalidad nueva allí.
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

Supabase utiliza PostgreSQL. El esquema de referencia está en `database/01_ddl_app_unificada_uae_postgres.sql`. Ejecútelo en el SQL Editor de un proyecto de desarrollo de Supabase o con `psql`. No sustituya el proyecto de Supabase de otra persona ni ejecute migraciones destructivas sin respaldo.

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
