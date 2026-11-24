# Asistencia académica

El prototipo registra asistencia por sesión del horario. Los estados permitidos
son `PRESENTE`, `RETARDO`, `FALTA` y `JUSTIFICADO`.

## Base de datos

Aplicar en orden después de las migraciones académicas:

1. `database/10_ddl_asistencia_academica_postgres.sql`
2. `database/11_dml_asistencia_demo_postgres.sql`

El seed genera historial únicamente para cuentas `*.prueba@uae.edu.mx`. Cada
fecha debe coincidir con el día de la semana de la sesión. La base impide que
una cuenta fuera del grupo reciba un registro y valida al docente que captura.

## API y cliente

- `GET /api/v1/academic/attendance`: historial propio de estudiante o sesiones
  asignadas al docente autenticado.
- `GET /api/v1/academic/attendance/roster?scheduleId=...&date=YYYY-MM-DD`:
  lista del grupo, limitada al docente dueño de la sesión.
- `POST /api/v1/academic/attendance`: registra o actualiza un estado de
  asistencia. Solo acepta sesiones asignadas al docente autenticado.

El cliente no envía un ID de docente para autorizarse; la API lo deriva del
token y la base vuelve a validar la relación con el horario.
