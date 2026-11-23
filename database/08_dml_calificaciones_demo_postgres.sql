-- Planes y entregables ficticios; no crea ni publica calificaciones.
-- Aplicar después de 07_ddl_calificaciones_academicas_postgres.sql.

BEGIN;

INSERT INTO planes_evaluacion (id_grupo, id_materia, id_docente)
SELECT id_grupo, id_materia, id_docente
FROM grupo_materias_docentes
ON CONFLICT (id_grupo, id_materia) DO UPDATE
SET id_docente = EXCLUDED.id_docente;

WITH ponderaciones (nombre, peso) AS (
  VALUES
    ('Parcial 1', 30::NUMERIC(5, 2)),
    ('Proyecto integrador', 30::NUMERIC(5, 2)),
    ('Evaluación final', 40::NUMERIC(5, 2))
)
INSERT INTO evaluaciones_academicas (id_plan, nombre, peso_porcentual)
SELECT p.id_plan, ponderaciones.nombre, ponderaciones.peso
FROM planes_evaluacion p
CROSS JOIN ponderaciones
ON CONFLICT (id_plan, nombre) DO UPDATE
SET peso_porcentual = EXCLUDED.peso_porcentual;

COMMIT;
