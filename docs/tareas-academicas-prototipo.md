# Tareas académicas de demostración

## Dónde está cada parte

- `database/05_ddl_tareas_academicas_postgres.sql`: asignación de materias a
  grupos y docentes, tareas, estados por estudiante, notificaciones y vistas.
- `database/06_dml_tareas_demo_postgres.sql`: tres tareas de ejemplo por grupo
  para probar tareas próximas, lejanas y vencidas.
- `database/07_ddl_calificaciones_academicas_postgres.sql` y
  `database/08_dml_calificaciones_demo_postgres.sql`: evaluación porcentual y
  sus entregables demo sin calificaciones.
- `database/tests/tareas_academicas_postgres.sql`: pruebas de aislamiento para
  Turismo e ITI, asignación docente, estados, tareas próximas y notificaciones.
  La prueba inserta datos temporales dentro de una transacción y termina con
  `ROLLBACK`.
- `database/tests/calificaciones_academicas_postgres.sql`: pruebas de
  calificaciones, disponibles después de aplicar el esquema y el seed de
  evaluación.
- `services/api-java`: aquí deberá implementarse el acceso autenticado y los
  endpoints. La API aún no está conectada a este modelo.
- `apps/mobile/lib/features/academic`: aquí deberá integrarse la interfaz
  móvil de tareas. La pantalla aún no está implementada.

## Checklist y alcance

| Punto | Estado |
|---|---|
| Crear tarea asociada a grupo, materia y docente asignado | Modelo SQL y datos de demostración |
| Asociar tarea a materia | Incluido; la base rechaza materias o docentes no asignados al grupo |
| Agregar descripción, fecha de entrega y prioridad | Incluido; prioridad: baja, media o alta |
| Estado pendiente | Es el estado inicial de cada estudiante |
| Estado en progreso | Se guarda por estudiante y tarea |
| Estado entregada | Se guarda por estudiante, con fecha de entrega |
| Estado vencida | Se calcula a partir de la fecha límite; no se guarda como estado permanente |
| Mostrar tareas próximas | Vista SQL con ventana de siete días |
| Crear notificación | Al crear una tarea, el trigger notifica a los estudiantes de su grupo |
| API, pantalla móvil y avisos automáticos de vencimiento | Pendientes |

Una entrega tardía sigue apareciendo como `ENTREGADA`; la vista también expone
`entrega_tardia`. Una tarea no entregada cuya fecha ya pasó aparece como
`VENCIDA`. La vista de próximas tareas incluye vencimientos desde ahora hasta
los siguientes siete días, en estado pendiente o en progreso.

## Aplicar en PostgreSQL de desarrollo

Ejecutar en este orden, desde la raíz del monorepo o en el editor SQL de una
base PostgreSQL de desarrollo:

1. `database/01_ddl_app_unificada_uae_postgres.sql`
2. `database/02_ddl_compatibilidad_supabase.sql`
3. `database/03_ddl_academico_postgres.sql`
4. `database/04_dml_academico_demo_postgres.sql`
5. `database/05_ddl_tareas_academicas_postgres.sql`
6. `database/06_dml_tareas_demo_postgres.sql`
7. `database/07_ddl_calificaciones_academicas_postgres.sql`
8. `database/08_dml_calificaciones_demo_postgres.sql`
9. `database/09_ddl_sesiones_identidad_postgres.sql`

Después de aplicar las migraciones, ejecutar según corresponda:

- `database/tests/tareas_academicas_postgres.sql`
- `database/tests/calificaciones_academicas_postgres.sql`

La prueba final debe terminar con `ROLLBACK` y no dejar cuentas, entregas,
tareas ni notificaciones de QA. Los datos del seed son ficticios, no tareas
oficiales. No ejecutar los scripts en una base productiva.

## Acceso y autorización

La vista `vista_tareas_estudiante` presenta las tareas del grupo vigente del
estudiante, y `vista_tareas_proximas_estudiante` limita el resultado a siete
días. La consulta de la API debe filtrar por el `id_usuario` obtenido de la
sesión validada en el servidor; nunca debe aceptar del cliente el ID de usuario,
grupo o carrera como criterio de autorización.

Antes de crear una tarea, la API también debe comprobar que la identidad
autenticada tiene rol docente y que ese docente está asignado a la materia del
grupo. El modelo SQL valida la asignación docente/materia/grupo y la pertenencia
del estudiante al grupo al registrar su progreso, pero las vistas por sí solas
no reemplazan la autorización del servidor.

La notificación implementada se crea al asignar la tarea. Los recordatorios
programados antes del vencimiento y las notificaciones push requieren un
servicio/API y no están incluidos en este prototipo.
