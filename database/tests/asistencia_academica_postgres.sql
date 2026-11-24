-- Valida los límites del modelo con cuentas ficticias y revierte los cambios.
-- Ejecutar después de 10_ddl_asistencia_academica_postgres.sql.

BEGIN;

DO $$
DECLARE
  v_student BIGINT;
  v_other_student BIGINT;
  v_schedule BIGINT;
  v_class_day VARCHAR(10);
  v_class_date DATE;
  v_rejected BOOLEAN;
BEGIN
  SELECT id_usuario INTO STRICT v_student FROM usuarios
  WHERE correo_institucional = 'diego.navarro.prueba@uae.edu.mx';
  SELECT id_usuario INTO STRICT v_other_student FROM usuarios
  WHERE correo_institucional = 'mateo.rios.prueba@uae.edu.mx';
  SELECT h.id_horario, h.dia_semana INTO STRICT v_schedule, v_class_day
  FROM horarios_academicos h
  JOIN usuarios u ON u.id_grupo = h.id_grupo
  WHERE u.id_usuario = v_student
  ORDER BY h.id_horario LIMIT 1;

  SELECT current_date - offset_days INTO STRICT v_class_date
  FROM generate_series(22, 45) AS offset_days
  WHERE extract(isodow FROM current_date - offset_days)::INTEGER =
    CASE v_class_day WHEN 'Lunes' THEN 1 WHEN 'Martes' THEN 2
      WHEN 'Miércoles' THEN 3 WHEN 'Jueves' THEN 4 WHEN 'Viernes' THEN 5 END
  ORDER BY offset_days LIMIT 1;

  INSERT INTO asistencias_academicas(
    id_horario, id_usuario, fecha_clase, estado
  ) VALUES (v_schedule, v_student, v_class_date, 'PRESENTE');

  v_rejected := FALSE;
  BEGIN
    INSERT INTO asistencias_academicas(
      id_horario, id_usuario, fecha_clase, estado
    ) VALUES (v_schedule, v_other_student, v_class_date, 'PRESENTE');
  EXCEPTION WHEN raise_exception THEN
    v_rejected := TRUE;
  END;
  IF NOT v_rejected THEN
    RAISE EXCEPTION 'El modelo aceptó un estudiante fuera del grupo.';
  END IF;

  v_rejected := FALSE;
  BEGIN
    INSERT INTO asistencias_academicas(
      id_horario, id_usuario, fecha_clase, estado
    ) VALUES (v_schedule, v_student, v_class_date + 1, 'PRESENTE');
  EXCEPTION WHEN raise_exception THEN
    v_rejected := TRUE;
  END;
  IF NOT v_rejected THEN
    RAISE EXCEPTION 'El modelo aceptó una fecha que no coincide con el horario.';
  END IF;
END;
$$;

ROLLBACK;
