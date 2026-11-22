-- Pruebas de integración que revierten todas las cuentas y entregas de QA.
-- Ejecutar después de las migraciones 03 y 05, y de los seeds 04 y 06,
-- en una base PostgreSQL de desarrollo.

BEGIN;

DO $$
DECLARE
  v_suffix TEXT := txid_current()::TEXT;
  v_turismo_usuario BIGINT;
  v_iti_usuario BIGINT;
  v_docente_usuario BIGINT;
  v_turismo_grupo BIGINT;
  v_iti_grupo BIGINT;
  v_turismo_docente BIGINT;
  v_turismo_materia BIGINT;
  v_iti_materia BIGINT;
  v_tarea_pendiente BIGINT;
  v_tarea_nueva BIGINT;
  v_tarea_total INTEGER;
  v_asignacion_total INTEGER;
  v_turismo_total INTEGER;
  v_turismo_otra_carrera INTEGER;
  v_iti_total INTEGER;
  v_iti_otra_carrera INTEGER;
  v_proximas INTEGER;
  v_estado TEXT;
  v_notificaciones INTEGER;
  v_rechazo_entrega BOOLEAN := FALSE;
  v_rechazo_docente BOOLEAN := FALSE;
BEGIN
  SELECT COUNT(*) INTO v_tarea_total FROM tareas_academicas;
  SELECT COUNT(*) INTO v_asignacion_total FROM grupo_materias_docentes;
  IF v_tarea_total <> 63 OR v_asignacion_total <> 147 THEN
    RAISE EXCEPTION
      'Seeds inesperados: tareas %, asignaciones grupo-materia %.',
      v_tarea_total, v_asignacion_total;
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

  SELECT gm.id_docente, gm.id_materia
  INTO STRICT v_turismo_docente, v_turismo_materia
  FROM grupo_materias_docentes gm
  JOIN materias m ON m.id_materia = gm.id_materia
  WHERE gm.id_grupo = v_turismo_grupo
    AND m.codigo = 'TUR-S01-M04';

  SELECT gm.id_materia INTO STRICT v_iti_materia
  FROM grupo_materias_docentes gm
  JOIN materias m ON m.id_materia = gm.id_materia
  WHERE gm.id_grupo = v_iti_grupo
    AND m.codigo = 'ITI-S03-M04';

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'QA temporal Turismo',
    'qa-tarea-' || v_suffix || '-tur@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'ESTUDIANTE'
  )
  RETURNING id_usuario INTO v_turismo_usuario;

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'QA temporal ITI',
    'qa-tarea-' || v_suffix || '-iti@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'ESTUDIANTE'
  )
  RETURNING id_usuario INTO v_iti_usuario;

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'QA temporal docente Turismo',
    'qa-tarea-' || v_suffix || '-doc@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'DOCENTE'
  )
  RETURNING id_usuario INTO v_docente_usuario;

  INSERT INTO roles (codigo, nombre) VALUES
    ('ESTUDIANTE', 'Estudiante'),
    ('DOCENTE', 'Docente')
  ON CONFLICT (codigo) DO NOTHING;

  INSERT INTO usuario_roles (id_usuario, id_rol)
  SELECT v_turismo_usuario, id_rol FROM roles WHERE codigo = 'ESTUDIANTE'
  ON CONFLICT DO NOTHING;

  INSERT INTO usuario_roles (id_usuario, id_rol)
  SELECT v_iti_usuario, id_rol FROM roles WHERE codigo = 'ESTUDIANTE'
  ON CONFLICT DO NOTHING;

  INSERT INTO usuario_roles (id_usuario, id_rol)
  SELECT v_docente_usuario, id_rol FROM roles WHERE codigo = 'DOCENTE'
  ON CONFLICT DO NOTHING;

  UPDATE usuarios
  SET id_grupo = v_turismo_grupo
  WHERE id_usuario = v_turismo_usuario;

  UPDATE usuarios
  SET id_grupo = v_iti_grupo
  WHERE id_usuario = v_iti_usuario;

  UPDATE docentes
  SET id_usuario = v_docente_usuario
  WHERE id_docente = v_turismo_docente;

  SELECT COUNT(*),
         COUNT(*) FILTER (WHERE codigo_carrera <> 'TUR')
  INTO v_turismo_total, v_turismo_otra_carrera
  FROM vista_tareas_estudiante
  WHERE id_usuario = v_turismo_usuario;

  SELECT COUNT(*),
         COUNT(*) FILTER (WHERE codigo_carrera <> 'ITI')
  INTO v_iti_total, v_iti_otra_carrera
  FROM vista_tareas_estudiante
  WHERE id_usuario = v_iti_usuario;

  IF v_turismo_total <> 3 OR v_turismo_otra_carrera <> 0 THEN
    RAISE EXCEPTION
      'Filtro de tareas Turismo incorrecto: total %, otras carreras %.',
      v_turismo_total, v_turismo_otra_carrera;
  END IF;

  IF v_iti_total <> 3 OR v_iti_otra_carrera <> 0 THEN
    RAISE EXCEPTION
      'Filtro de tareas ITI incorrecto: total %, otras carreras %.',
      v_iti_total, v_iti_otra_carrera;
  END IF;

  SELECT COUNT(*) INTO v_proximas
  FROM vista_tareas_proximas_estudiante
  WHERE id_usuario = v_turismo_usuario;

  IF v_proximas <> 1 THEN
    RAISE EXCEPTION 'Se esperaba una tarea próxima para Turismo; se obtuvo %.',
      v_proximas;
  END IF;

  SELECT id_tarea, estado
  INTO STRICT v_tarea_pendiente, v_estado
  FROM vista_tareas_estudiante
  WHERE id_usuario = v_turismo_usuario
    AND codigo_demo = 'DEMO-TUR-S01-T01';

  IF v_estado <> 'PENDIENTE' THEN
    RAISE EXCEPTION 'Estado pendiente incorrecto: %.', v_estado;
  END IF;

  SELECT estado INTO STRICT v_estado
  FROM vista_tareas_estudiante
  WHERE id_usuario = v_turismo_usuario
    AND codigo_demo = 'DEMO-TUR-S01-T03';

  IF v_estado <> 'VENCIDA' THEN
    RAISE EXCEPTION 'El estado vencida no se calculó correctamente: %.', v_estado;
  END IF;

  INSERT INTO entregas_tareas (id_tarea, id_grupo, id_usuario, estado)
  VALUES (
    v_tarea_pendiente,
    v_turismo_grupo,
    v_turismo_usuario,
    'EN_PROGRESO'
  );

  SELECT estado INTO STRICT v_estado
  FROM vista_tareas_estudiante
  WHERE id_usuario = v_turismo_usuario
    AND id_tarea = v_tarea_pendiente;

  IF v_estado <> 'EN_PROGRESO' THEN
    RAISE EXCEPTION 'El estado en progreso no se guardó correctamente: %.',
      v_estado;
  END IF;

  UPDATE entregas_tareas
  SET estado = 'ENTREGADA',
      fecha_entregada = now(),
      contenido_entrega = 'Entrega de QA'
  WHERE id_tarea = v_tarea_pendiente
    AND id_usuario = v_turismo_usuario;

  SELECT estado INTO STRICT v_estado
  FROM vista_tareas_estudiante
  WHERE id_usuario = v_turismo_usuario
    AND id_tarea = v_tarea_pendiente;

  IF v_estado <> 'ENTREGADA' THEN
    RAISE EXCEPTION 'El estado entregada no se guardó correctamente: %.',
      v_estado;
  END IF;

  BEGIN
    INSERT INTO entregas_tareas (
      id_tarea, id_grupo, id_usuario, estado
    )
    VALUES (
      v_tarea_pendiente,
      v_turismo_grupo,
      v_iti_usuario,
      'EN_PROGRESO'
    );
  EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
      v_rechazo_entrega := TRUE;
  END;

  IF NOT v_rechazo_entrega THEN
    RAISE EXCEPTION
      'Se permitió entregar una tarea de Turismo desde una cuenta ITI.';
  END IF;

  INSERT INTO tareas_academicas (
    id_grupo, id_materia, id_docente, titulo, descripcion,
    fecha_entrega, prioridad
  )
  VALUES (
    v_turismo_grupo,
    v_turismo_materia,
    v_turismo_docente,
    'Tarea de notificación QA',
    'Registro temporal para probar el aviso al grupo.',
    now() + INTERVAL '5 days',
    'MEDIA'
  )
  RETURNING id_tarea INTO v_tarea_nueva;

  SELECT COUNT(*) INTO v_notificaciones
  FROM notificaciones
  WHERE id_tarea = v_tarea_nueva
    AND tipo = 'TAREA_CREADA'
    AND id_usuario = v_turismo_usuario;

  IF v_notificaciones <> 1 THEN
    RAISE EXCEPTION
      'La tarea nueva no generó una notificación para Turismo.';
  END IF;

  SELECT COUNT(*) INTO v_notificaciones
  FROM notificaciones
  WHERE id_tarea = v_tarea_nueva
    AND id_usuario = v_iti_usuario;

  IF v_notificaciones <> 0 THEN
    RAISE EXCEPTION
      'La notificación de Turismo llegó a una cuenta ITI.';
  END IF;

  SELECT COUNT(*) INTO v_proximas
  FROM vista_tareas_proximas_estudiante
  WHERE id_usuario = v_turismo_usuario;

  IF v_proximas <> 2 THEN
    RAISE EXCEPTION
      'La tarea nueva no aparece en próximas tareas; se obtuvieron %.',
      v_proximas;
  END IF;

  BEGIN
    INSERT INTO tareas_academicas (
      id_grupo, id_materia, id_docente, titulo, descripcion,
      fecha_entrega, prioridad
    )
    VALUES (
      v_turismo_grupo,
      v_iti_materia,
      v_turismo_docente,
      'Tarea con asignación incorrecta',
      'Debe fallar porque esa materia y docente pertenecen a otro grupo.',
      now() + INTERVAL '5 days',
      'BAJA'
    );
  EXCEPTION
    WHEN foreign_key_violation THEN
      v_rechazo_docente := TRUE;
  END;

  IF NOT v_rechazo_docente THEN
    RAISE EXCEPTION
      'Se permitió asignar una materia ITI a un grupo de Turismo.';
  END IF;

  RAISE NOTICE
    'OK: Turismo %, ITI %, estados, próximas tareas y notificación aislada.',
    v_turismo_total, v_iti_total;
END
$$;

ROLLBACK;
