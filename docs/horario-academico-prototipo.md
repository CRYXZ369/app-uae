# Horario académico de demostración

## Dónde está cada parte

- `database/03_ddl_academico_postgres.sql`: carreras, semestres, grupos,
  materias, docentes, aulas, talleres y sesiones de horario.
- `database/04_dml_academico_demo_postgres.sql`: catálogos y horarios ficticios
  para probar el modelo.
- `database/tests/horario_academico_postgres.sql`: pruebas de Turismo, ITI,
  docente, talleres, duración y conflictos de horario. La prueba inserta
  usuarios temporales dentro de una transacción y termina con `ROLLBACK`.
- `services/api-java`: aquí deberá implementarse la consulta del horario en
  `academic` usando el ID del usuario autenticado. El servicio Java aún no está
  implementado.
- `apps/mobile/lib/features/academic`: aquí irá posteriormente la pantalla
  Flutter del horario. Esa feature aún no existe.

## Datos de demostración

El seed crea las carreras Ingeniería en Tecnologías de la Información (ITI),
Turismo y Licenciatura en Administración; semestres 1 al 7 y un grupo A por
carrera y semestre. Para tener un horario de semana útil, se asumen siete
materias por semestre (49 por carrera), no siete materias para toda la carrera.
Los nombres, grupos y horarios son ejemplos: no son oferta académica ni
asignaciones oficiales.

Las clases se programan de lunes a viernes, entre las 8:00 y las 15:00, con
duraciones de 2 a 4 horas. Los semestres 1 al 6 tienen exactamente un taller
semanal de una hora; el séptimo no tiene taller. El esquema rechaza horarios
fuera de esa ventana, talleres en séptimo semestre y cruces de grupo, docente
o aula.

## Aislamiento por usuario

El estudiante tiene su grupo vigente en `usuarios.id_grupo`. La consulta del
horario debe obtener ese grupo por el ID derivado de la sesión verificada, no
por un `id_usuario`, carrera, semestre o grupo enviados libremente por Flutter:

```sql
SELECT h.dia_semana,
       h.hora_inicio,
       h.hora_fin,
       COALESCE(m.nombre, t.nombre) AS actividad,
       d.nombre_completo AS docente,
       a.nombre AS aula,
       c.nombre AS carrera,
       g.nombre AS grupo
FROM usuarios u
JOIN grupos g ON g.id_grupo = u.id_grupo
JOIN carreras c ON c.id_carrera = g.id_carrera
JOIN horarios_academicos h ON h.id_grupo = g.id_grupo
LEFT JOIN materias m ON m.id_materia = h.id_materia
LEFT JOIN talleres t ON t.id_taller = h.id_taller
JOIN docentes d ON d.id_docente = h.id_docente
JOIN aulas a ON a.id_aula = h.id_aula
WHERE u.id_usuario = $1
  AND EXISTS (
    SELECT 1
    FROM usuario_roles ur
    JOIN roles r ON r.id_rol = ur.id_rol
    WHERE ur.id_usuario = u.id_usuario
      AND r.codigo = 'ESTUDIANTE'
  )
ORDER BY CASE h.dia_semana
           WHEN 'Lunes' THEN 1
           WHEN 'Martes' THEN 2
           WHEN 'Miércoles' THEN 3
           WHEN 'Jueves' THEN 4
           ELSE 5
         END,
         h.hora_inicio;
```

Para un docente, la API debe buscar sus sesiones mediante
`docentes.id_usuario = $1` y verificar el rol `DOCENTE` con `usuario_roles` y
`roles`. El seed deja esa relación sin asignar, porque no crea cuentas ni
contraseñas de acceso. La interfaz nunca es la frontera de seguridad: la API
debe derivar `$1` de la identidad autenticada.

```sql
SELECT h.dia_semana,
       h.hora_inicio,
       h.hora_fin,
       COALESCE(m.nombre, t.nombre) AS actividad,
       a.nombre AS aula,
       g.nombre AS grupo,
       c.nombre AS carrera
FROM usuarios u
JOIN docentes d ON d.id_usuario = u.id_usuario
JOIN horarios_academicos h ON h.id_docente = d.id_docente
JOIN grupos g ON g.id_grupo = h.id_grupo
JOIN carreras c ON c.id_carrera = h.id_carrera
LEFT JOIN materias m ON m.id_materia = h.id_materia
LEFT JOIN talleres t ON t.id_taller = h.id_taller
JOIN aulas a ON a.id_aula = h.id_aula
WHERE u.id_usuario = $1
  AND EXISTS (
    SELECT 1
    FROM usuario_roles ur
    JOIN roles r ON r.id_rol = ur.id_rol
    WHERE ur.id_usuario = u.id_usuario
      AND r.codigo = 'DOCENTE'
  )
ORDER BY CASE h.dia_semana
           WHEN 'Lunes' THEN 1
           WHEN 'Martes' THEN 2
           WHEN 'Miércoles' THEN 3
           WHEN 'Jueves' THEN 4
           ELSE 5
         END,
         h.hora_inicio;
```

## Cómo probarlo en PostgreSQL de desarrollo

Aplicar en este orden:

1. `database/01_ddl_app_unificada_uae_postgres.sql`
2. `database/02_ddl_compatibilidad_supabase.sql`
3. `database/03_ddl_academico_postgres.sql`
4. `database/04_dml_academico_demo_postgres.sql`
5. `database/tests/horario_academico_postgres.sql`

La prueba debe terminar con `ROLLBACK`; no deja las cuentas QA en la base. Para
Supabase, revisar los permisos de la extensión `btree_gist` al aplicar la
migración. No usar estos datos como horarios oficiales.
