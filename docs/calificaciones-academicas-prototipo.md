# Calificaciones y progreso académico

## Dónde está cada parte

- `database/07_ddl_calificaciones_academicas_postgres.sql`: escala, planes de
  evaluación, porcentajes por entregable, calificaciones y vistas de consulta.
- `database/08_dml_calificaciones_demo_postgres.sql`: crea planes para las
  materias de demostración, sin registrar notas de estudiantes.
- `database/tests/calificaciones_academicas_postgres.sql`: comprueba Turismo,
  ITI, materias sin notas, promedios, ponderaciones y asignación del docente.
  Los datos de QA se revierten al finalizar.
- `apps/mobile/lib/features/grades/domain/course_grade_summary.dart`: calcula
  el promedio estimado y el porcentaje ponderado calificado.
- `apps/mobile/lib/features/grades/presentation/course_grades_screen.dart`:
  vista de consulta, con aviso de estimación y sin controles para editar.
- `apps/mobile/test/features/grades/course_grade_summary_test.dart`: pruebas
  de cálculo, escala, materias sin notas y pantalla de solo lectura.
- `services/api-java/.../grades/GradesController.java`: `GET /api/v1/grades/courses`
  valida el token, exige el rol de estudiante y solo
  entrega sus materias.
- `apps/mobile/lib/features/auth/data/identity_api.dart` y
  `apps/mobile/lib/features/home/presentation/home_screen.dart`: conectan la
  consulta a la API y abren la vista desde el inicio.

## Checklist y decisiones para este prototipo

| Punto | Estado |
|---|---|
| Definir escala evaluativa | Escala de 0 a 100; falta confirmación oficial de la universidad |
| Definir porcentaje de cada entregable | Datos demo: Parcial 1 = 30%, Proyecto integrador = 30%, Evaluación final = 40% |
| Registrar calificaciones | Modelo SQL acepta notas de docente asignado; falta el endpoint autenticado de captura |
| Calcular promedio estimado | Vista SQL, API autenticada y modelo Dart; pondera solo entregables con nota y normaliza por su peso calificado |
| Mostrar progreso del curso | Vista SQL y móvil muestran la ponderación que ya tiene calificación |
| Indicar que es una estimación | Aviso permanente en la pantalla; el promedio se etiqueta como estimado |
| No permitir que el alumno cambie calificaciones | Pantalla y endpoint móvil son de solo lectura; la API no expone escritura al alumno |
| Permitir al docente actualizar su grupo | La base valida asignación; faltan endpoint autenticado y pantalla de captura |
| Probar materias sin calificaciones | Pruebas SQL para Turismo/ITI y Flutter para promedio vacío y progreso 0% |

El 30/30/40 es un ejemplo, no un porcentaje institucional. La base permite
distribuciones alternativas siempre que no excedan 100%; la estimación solo se
calcula cuando el plan completo suma exactamente 100%. Antes de habilitar una
materia, el docente debe definir la ponderación completa. No se asigna
calificación aprobatoria porque la universidad debe confirmar ese criterio.

El promedio estimado se calcula como
`sum(calificacion * ponderacion) / sum(ponderacion calificada)`. Por ejemplo,
una nota de 90 en un entregable con ponderación de 30% muestra un estimado de
90/100 y un progreso ponderado de 30%. El progreso representa la parte del
curso que ya tiene calificación; no mide tiempo transcurrido ni asistencia. Si
no hay notas, el promedio es “sin calificaciones” y el progreso es cero. Si el
plan no suma 100%, no se muestra promedio.

## Seguridad y alcance

El estudiante consulta únicamente sus materias y no recibe una función de
edición. La autorización real requiere que la API derive la identidad del
token validado: el alumno solo puede leer su propia fila, y la escritura debe
rechazarse para estudiantes. Para capturar o corregir una nota, la API debe
verificar que el usuario autenticado tenga rol `DOCENTE` y que su cuenta esté
vinculada al docente asignado a esa materia y grupo; no debe confiar en IDs de
usuario o docente enviados por Flutter.

La pantalla de consulta ya está conectada al inicio y a la API. El endpoint
`GET /api/v1/grades/courses` valida sesión y rol; la captura/corrección de notas
por docentes todavía no está disponible. La API debe mantener cualquier
escritura restringida al docente asignado, aunque se agregue la interfaz.

## Cómo aplicar y probar en PostgreSQL de desarrollo

Después de los seeds existentes, ejecutar:

1. `database/07_ddl_calificaciones_academicas_postgres.sql`
2. `database/08_dml_calificaciones_demo_postgres.sql`
3. `database/tests/calificaciones_academicas_postgres.sql`

La prueba final usa una transacción con `ROLLBACK`. No crea calificaciones
persistentes ni cuentas de prueba. Los datos demo no son notas oficiales y no
deben aplicarse en una base productiva.
