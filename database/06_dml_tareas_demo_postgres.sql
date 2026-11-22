-- Asignaciones y tareas ficticias para desarrollo.
-- Aplicar después de 05_ddl_tareas_academicas_postgres.sql.
-- Las tareas con codigo_demo no generan notificaciones a usuarios reales.

BEGIN;

INSERT INTO grupo_materias_docentes (
  id_grupo, id_carrera, numero_semestre, id_materia, id_docente
)
SELECT DISTINCT h.id_grupo,
       h.id_carrera,
       h.numero_semestre,
       h.id_materia,
       h.id_docente
FROM horarios_academicos h
WHERE h.id_materia IS NOT NULL
ON CONFLICT (id_grupo, id_materia) DO UPDATE
SET id_carrera = EXCLUDED.id_carrera,
    numero_semestre = EXCLUDED.numero_semestre,
    id_docente = EXCLUDED.id_docente;

WITH tareas_demo (secuencia, tipo, dias, prioridad, descripcion) AS (
  VALUES
    (1, 'Entrega semanal', 2, 'ALTA',
      'Resuelve y entrega la actividad asignada en clase.'),
    (2, 'Ejercicio de aplicación', 10, 'MEDIA',
      'Aplica los conceptos de la materia a un caso práctico.'),
    (3, 'Lectura de preparación', -2, 'BAJA',
      'Revisa el material indicado y prepara un resumen.')
),
asignaciones AS (
  SELECT c.codigo AS codigo_carrera,
         g.id_grupo,
         g.numero_semestre,
         m.id_materia,
         gm.id_docente,
         m.nombre AS nombre_materia,
         demo.secuencia,
         demo.tipo,
         demo.dias,
         demo.prioridad,
         demo.descripcion
  FROM grupos g
  JOIN carreras c ON c.id_carrera = g.id_carrera
  JOIN materias m
    ON m.id_carrera = g.id_carrera
    AND m.numero_semestre = g.numero_semestre
  JOIN grupo_materias_docentes gm
    ON gm.id_grupo = g.id_grupo
    AND gm.id_materia = m.id_materia
  JOIN tareas_demo demo
    ON m.codigo = c.codigo || '-S' ||
      LPAD(g.numero_semestre::TEXT, 2, '0') || '-M' ||
      LPAD(demo.secuencia::TEXT, 2, '0')
)
INSERT INTO tareas_academicas (
  codigo_demo,
  id_grupo,
  id_materia,
  id_docente,
  titulo,
  descripcion,
  fecha_entrega,
  prioridad
)
SELECT 'DEMO-' || codigo_carrera || '-S' ||
         LPAD(numero_semestre::TEXT, 2, '0') ||
         '-T' || LPAD(secuencia::TEXT, 2, '0'),
       id_grupo,
       id_materia,
       id_docente,
       tipo || ': ' || nombre_materia,
       descripcion,
       now() + dias * INTERVAL '1 day',
       prioridad
FROM asignaciones
ON CONFLICT (codigo_demo) DO UPDATE
SET id_grupo = EXCLUDED.id_grupo,
    id_materia = EXCLUDED.id_materia,
    id_docente = EXCLUDED.id_docente,
    titulo = EXCLUDED.titulo,
    descripcion = EXCLUDED.descripcion,
    fecha_entrega = EXCLUDED.fecha_entrega,
    prioridad = EXCLUDED.prioridad;

COMMIT;
