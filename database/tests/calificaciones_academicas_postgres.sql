-- Pruebas de calificaciones con datos temporales que se revierten al final.
-- Ejecutar después de las migraciones y seeds 01, 03-08 de PostgreSQL.

BEGIN;

DO $$
DECLARE
  v_suffix TEXT := txid_current()::TEXT;
  v_turismo_usuario BIGINT;
  v_iti_usuario BIGINT;
  v_docente_usuario BIGINT;
  v_docente_no_asignado_usuario BIGINT;
  v_turismo_grupo BIGINT;
  v_iti_grupo BIGINT;
  v_turismo_docente BIGINT;
  v_docente_no_asignado BIGINT;
  v_turismo_plan BIGINT;
  v_evaluacion_1 BIGINT;
  v_evaluacion_2 BIGINT;
  v_evaluacion_3 BIGINT;
  v_total_planes INTEGER;
  v_total_evaluaciones INTEGER;
  v_materias_turismo INTEGER;
  v_materias_iti INTEGER;
  v_promedio NUMERIC(5, 2);
  v_progreso NUMERIC(5, 2);
  v_ponderacion NUMERIC(5, 2);
  v_calificadas INTEGER;
  v_plan_completo BOOLEAN;
  v_rechazo_alumno_otro_grupo BOOLEAN := FALSE;
  v_rechazo_docente_no_asignado BOOLEAN := FALSE;
  v_rechazo_peso_excedido BOOLEAN := FALSE;
BEGIN
  SELECT COUNT(*) INTO v_total_planes FROM planes_evaluacion;
  SELECT COUNT(*) INTO v_total_evaluaciones FROM evaluaciones_academicas;
  IF v_total_planes <> 147 OR v_total_evaluaciones <> 441 THEN
    RAISE EXCEPTION
      'Seeds inesperados: planes %, entregables %.',
      v_total_planes, v_total_evaluaciones;
  END IF;

  IF EXISTS (
    SELECT p.id_plan
    FROM planes_evaluacion p
    JOIN evaluaciones_academicas e ON e.id_plan = p.id_plan
    GROUP BY p.id_plan
    HAVING SUM(e.peso_porcentual) <> 100
  ) THEN
    RAISE EXCEPTION 'Hay planes demo cuya ponderación no suma 100%%.';
  END IF;

  SELECT g.id_grupo INTO STRICT v_turismo_grupo
  FROM grupos g
  JOIN carreras c ON c.id_carrera = g.id_carrera
  WHERE c.codigo = 'TUR'
    AND g.numero_semestre = 1
    AND g.codigo = 'S1-A';

  SELECT g.id_grupo INTO STRICT v_iti_grupo
  FROM grupos g
  JOIN carreras c ON c.id_carrera = g.id_carrera
  WHERE c.codigo = 'ITI'
    AND g.numero_semestre = 3
    AND g.codigo = 'S3-A';

  SELECT p.id_plan, p.id_docente
  INTO STRICT v_turismo_plan, v_turismo_docente
  FROM planes_evaluacion p
  JOIN materias m ON m.id_materia = p.id_materia
  WHERE p.id_grupo = v_turismo_grupo
    AND m.codigo = 'TUR-S01-M01';

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'QA calificaciones Turismo',
    'qa-notas-' || v_suffix || '-tur@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'ESTUDIANTE'
  )
  RETURNING id_usuario INTO v_turismo_usuario;

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'QA calificaciones ITI',
    'qa-notas-' || v_suffix || '-iti@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'ESTUDIANTE'
  )
  RETURNING id_usuario INTO v_iti_usuario;

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'QA docente asignado',
    'qa-notas-' || v_suffix || '-doc@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'DOCENTE'
  )
  RETURNING id_usuario INTO v_docente_usuario;

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'QA docente no asignado',
    'qa-notas-' || v_suffix || '-otro@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'DOCENTE'
  )
  RETURNING id_usuario INTO v_docente_no_asignado_usuario;

  SELECT id_docente INTO STRICT v_docente_no_asignado
  FROM docentes
  WHERE codigo = 'TUR-DOC-02';

  UPDATE docentes
  SET id_usuario = v_docente_usuario
  WHERE id_docente = v_turismo_docente;

  UPDATE docentes
  SET id_usuario = (
    SELECT id_usuario
    FROM usuarios
    WHERE email = 'qa-notas-' || v_suffix || '-otro@uae.edu.mx'
  )
  WHERE id_docente = v_docente_no_asignado;

  INSERT INTO roles (codigo, nombre) VALUES
    ('ESTUDIANTE', 'Estudiante'),
    ('DOCENTE', 'Docente')
  ON CONFLICT (codigo) DO NOTHING;

  INSERT INTO usuario_roles (id_usuario, id_rol)
  SELECT usuarios.id_usuario, roles.id_rol
  FROM usuarios
  CROSS JOIN roles
  WHERE usuarios.id_usuario IN (
      v_turismo_usuario,
      v_iti_usuario,
      v_docente_usuario,
      v_docente_no_asignado_usuario
    )
    AND (
      (usuarios.id_usuario IN (v_turismo_usuario, v_iti_usuario)
        AND roles.codigo = 'ESTUDIANTE')
      OR
      (usuarios.id_usuario IN (
        v_docente_usuario,
        v_docente_no_asignado_usuario
      ) AND roles.codigo = 'DOCENTE')
    )
  ON CONFLICT DO NOTHING;

  UPDATE usuarios
  SET id_grupo = v_turismo_grupo
  WHERE id_usuario = v_turismo_usuario;

  UPDATE usuarios
  SET id_grupo = v_iti_grupo
  WHERE id_usuario = v_iti_usuario;

  SELECT COUNT(*) INTO v_materias_turismo
  FROM vista_progreso_calificaciones_estudiante
  WHERE id_usuario = v_turismo_usuario
    AND codigo_carrera = 'TUR'
    AND promedio_estimado IS NULL
    AND progreso_curso = 0
    AND plan_completo;

  SELECT COUNT(*) INTO v_materias_iti
  FROM vista_progreso_calificaciones_estudiante
  WHERE id_usuario = v_iti_usuario
    AND codigo_carrera = 'ITI'
    AND promedio_estimado IS NULL
    AND progreso_curso = 0
    AND plan_completo;

  IF v_materias_turismo <> 7 OR v_materias_iti <> 7 THEN
    RAISE EXCEPTION
      'Las materias sin notas no se muestran correctamente (Turismo %, ITI %).',
      v_materias_turismo, v_materias_iti;
  END IF;

  SELECT id_evaluacion INTO STRICT v_evaluacion_1
  FROM evaluaciones_academicas
  WHERE id_plan = v_turismo_plan
    AND nombre = 'Parcial 1';

  SELECT id_evaluacion INTO STRICT v_evaluacion_2
  FROM evaluaciones_academicas
  WHERE id_plan = v_turismo_plan
    AND nombre = 'Proyecto integrador';

  SELECT id_evaluacion INTO STRICT v_evaluacion_3
  FROM evaluaciones_academicas
  WHERE id_plan = v_turismo_plan
    AND nombre = 'Evaluación final';

  INSERT INTO calificaciones_academicas (
    id_evaluacion, id_plan, id_usuario, calificacion, calificada_por
  )
  VALUES (
    v_evaluacion_1, v_turismo_plan, v_turismo_usuario, 80, v_turismo_docente
  );

  SELECT promedio_estimado, progreso_curso, entregables_calificados,
         plan_completo
  INTO STRICT v_promedio, v_progreso, v_calificadas, v_plan_completo
  FROM vista_progreso_calificaciones_estudiante
  WHERE id_usuario = v_turismo_usuario
    AND id_plan = v_turismo_plan;

  IF v_promedio <> 80 OR v_progreso <> 30 OR v_calificadas <> 1
     OR NOT v_plan_completo THEN
    RAISE EXCEPTION
      'Resumen parcial inesperado: promedio %, progreso %, notas %, plan completo %.',
      v_promedio, v_progreso, v_calificadas, v_plan_completo;
  END IF;

  UPDATE calificaciones_academicas
  SET calificacion = 90,
      calificada_por = v_turismo_docente
  WHERE id_evaluacion = v_evaluacion_1
    AND id_usuario = v_turismo_usuario;

  INSERT INTO calificaciones_academicas (
    id_evaluacion, id_plan, id_usuario, calificacion, calificada_por
  )
  VALUES
    (
      v_evaluacion_2,
      v_turismo_plan,
      v_turismo_usuario,
      95,
      v_turismo_docente
    ),
    (
      v_evaluacion_3,
      v_turismo_plan,
      v_turismo_usuario,
      70,
      v_turismo_docente
    );

  SELECT promedio_estimado, progreso_curso, ponderacion_total
  INTO STRICT v_promedio, v_progreso, v_ponderacion
  FROM vista_progreso_calificaciones_estudiante
  WHERE id_usuario = v_turismo_usuario
    AND id_plan = v_turismo_plan;

  IF v_promedio <> 83.5 OR v_progreso <> 100 OR v_ponderacion <> 100 THEN
    RAISE EXCEPTION
      'Resumen completo inesperado: promedio %, progreso %, ponderación %.',
      v_promedio, v_progreso, v_ponderacion;
  END IF;

  BEGIN
    INSERT INTO calificaciones_academicas (
      id_evaluacion, id_plan, id_usuario, calificacion, calificada_por
    )
    VALUES (
      v_evaluacion_1,
      v_turismo_plan,
      v_iti_usuario,
      85,
      v_turismo_docente
    );
  EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
      v_rechazo_alumno_otro_grupo := TRUE;
  END;

  IF NOT v_rechazo_alumno_otro_grupo THEN
    RAISE EXCEPTION
      'Se permitió registrar una calificación a un alumno de otro grupo.';
  END IF;

  BEGIN
    INSERT INTO calificaciones_academicas (
      id_evaluacion, id_plan, id_usuario, calificacion, calificada_por
    )
    VALUES (
      v_evaluacion_1,
      v_turismo_plan,
      v_turismo_usuario,
      85,
      v_docente_no_asignado
    )
    ON CONFLICT (id_evaluacion, id_usuario) DO UPDATE
    SET calificacion = EXCLUDED.calificacion,
        calificada_por = EXCLUDED.calificada_por;
  EXCEPTION
    WHEN foreign_key_violation THEN
      v_rechazo_docente_no_asignado := TRUE;
  END;

  IF NOT v_rechazo_docente_no_asignado THEN
    RAISE EXCEPTION
      'Se permitió que un docente no asignado modifique una calificación.';
  END IF;

  BEGIN
    INSERT INTO evaluaciones_academicas (id_plan, nombre, peso_porcentual)
    VALUES (v_turismo_plan, 'Ponderación excedida QA', 1);
  EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
      v_rechazo_peso_excedido := TRUE;
  END;

  IF NOT v_rechazo_peso_excedido THEN
    RAISE EXCEPTION
      'Se permitió superar el 100%% de ponderación del plan.';
  END IF;

  RAISE NOTICE
    'OK: escala 0-100, progreso ponderado, materias sin notas y permisos de asignación.';
END
$$;

ROLLBACK;
