-- Relaciones e historial ficticios para cuentas de prueba solamente.
-- Aplicar después de 10_ddl_asistencia_academica_postgres.sql.

-- Enlaza la cuenta docente ficticia a una asignación de demostración para
-- habilitar la prueba de lista; no reemplaza docentes ya vinculados.
UPDATE docentes d
SET id_usuario = u.id_usuario
FROM usuarios u
WHERE u.correo_institucional = 'elena.vargas.prueba@uae.edu.mx'
  AND d.id_docente = (
    SELECT gm.id_docente
    FROM grupo_materias_docentes gm
    WHERE gm.id_grupo = 90
    ORDER BY gm.id_materia
    LIMIT 1
  )
  AND (d.id_usuario IS NULL OR d.id_usuario = u.id_usuario);

INSERT INTO asistencias_academicas (
  id_horario, id_usuario, fecha_clase, estado
)
SELECT h.id_horario, u.id_usuario, d.fecha_clase,
       CASE (extract(isodow FROM d.fecha_clase)::INTEGER + h.id_horario::INTEGER) % 12
         WHEN 0 THEN 'RETARDO'
         WHEN 1 THEN 'FALTA'
         ELSE 'PRESENTE'
       END
FROM usuarios u
JOIN usuario_roles ur ON ur.id_usuario = u.id_usuario
JOIN roles r ON r.id_rol = ur.id_rol AND r.codigo = 'ESTUDIANTE'
JOIN horarios_academicos h ON h.id_grupo = u.id_grupo
CROSS JOIN LATERAL (
  SELECT current_date - day_offset AS fecha_clase
  FROM generate_series(1, 21) AS day_offset
) d
WHERE u.correo_institucional LIKE '%.prueba@uae.edu.mx'
  AND CASE h.dia_semana
        WHEN 'Lunes' THEN 1
        WHEN 'Martes' THEN 2
        WHEN 'Miércoles' THEN 3
        WHEN 'Jueves' THEN 4
        WHEN 'Viernes' THEN 5
      END = extract(isodow FROM d.fecha_clase)::INTEGER
ON CONFLICT (id_horario, id_usuario, fecha_clase) DO NOTHING;
