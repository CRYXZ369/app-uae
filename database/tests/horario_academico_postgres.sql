-- Pruebas de integración destructivas solo dentro de una transacción que revierte.
-- Ejecutar después de 03_ddl_academico_postgres.sql y
-- 04_dml_academico_demo_postgres.sql en una base PostgreSQL de desarrollo.

BEGIN;

DO $$
DECLARE
  v_suffix TEXT := txid_current()::TEXT;
  v_turismo_usuario BIGINT;
  v_iti_usuario BIGINT;
  v_docente_usuario BIGINT;
  v_turismo_grupo BIGINT;
  v_iti_grupo BIGINT;
  v_turismo_total INTEGER;
  v_turismo_otra_carrera INTEGER;
  v_iti_total INTEGER;
  v_iti_otra_carrera INTEGER;
  v_docente_total INTEGER;
  v_docente_otra_carrera INTEGER;
  v_carreras_total INTEGER;
  v_semestres_total INTEGER;
  v_grupos_total INTEGER;
  v_materias_total INTEGER;
  v_horarios_total INTEGER;
  v_talleres_total INTEGER;
  v_talleres_semestre_7 INTEGER;
  v_hay_choques BOOLEAN;
  v_hay_duracion_2 BOOLEAN;
  v_hay_duracion_3 BOOLEAN;
  v_hay_duracion_4 BOOLEAN;
BEGIN
  SELECT COUNT(*) INTO v_carreras_total FROM carreras
  WHERE codigo IN ('ITI', 'TUR', 'ADM');
  SELECT COUNT(*) INTO v_semestres_total FROM semestres;
  SELECT COUNT(*) INTO v_grupos_total FROM grupos;
  SELECT COUNT(*) INTO v_materias_total FROM materias;
  SELECT COUNT(*) INTO v_horarios_total FROM horarios_academicos;

  IF v_carreras_total <> 3
     OR v_semestres_total <> 7
     OR v_grupos_total <> 21
     OR v_materias_total <> 147
     OR v_horarios_total <> 165 THEN
    RAISE EXCEPTION
      'Catálogos inesperados: carreras %, semestres %, grupos %, materias %, sesiones %.',
      v_carreras_total, v_semestres_total, v_grupos_total,
      v_materias_total, v_horarios_total;
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

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'Prueba temporal Turismo',
    'qa-' || v_suffix || '-tur@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'ESTUDIANTE'
  )
  RETURNING id_usuario INTO v_turismo_usuario;

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'Prueba temporal ITI',
    'qa-' || v_suffix || '-iti@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'ESTUDIANTE'
  )
  RETURNING id_usuario INTO v_iti_usuario;

  INSERT INTO usuarios (nombre_completo, email, password_hash, rol)
  VALUES (
    'Prueba temporal docente',
    'qa-' || v_suffix || '-doc@uae.edu.mx',
    '!HASH_INVALIDO_SOLO_PRUEBA!',
    'DOCENTE'
  )
  RETURNING id_usuario INTO v_docente_usuario;

  INSERT INTO roles (codigo, nombre) VALUES
    ('ESTUDIANTE', 'Estudiante'),
    ('DOCENTE', 'Docente')
  ON CONFLICT (codigo) DO NOTHING;

  INSERT INTO usuario_roles (id_usuario, id_rol)
  SELECT v_turismo_usuario, r.id_rol
  FROM roles r
  WHERE r.codigo = 'ESTUDIANTE'
  ON CONFLICT DO NOTHING;

  INSERT INTO usuario_roles (id_usuario, id_rol)
  SELECT v_iti_usuario, r.id_rol
  FROM roles r
  WHERE r.codigo = 'ESTUDIANTE'
  ON CONFLICT DO NOTHING;

  INSERT INTO usuario_roles (id_usuario, id_rol)
  SELECT v_docente_usuario, r.id_rol
  FROM roles r
  WHERE r.codigo = 'DOCENTE'
  ON CONFLICT DO NOTHING;

  UPDATE usuarios
  SET id_grupo = v_turismo_grupo
  WHERE id_usuario = v_turismo_usuario;

  UPDATE usuarios
  SET id_grupo = v_iti_grupo
  WHERE id_usuario = v_iti_usuario;

  UPDATE docentes
  SET id_usuario = v_docente_usuario
  WHERE codigo = 'ITI-DOC-01';

  SELECT COUNT(*),
         COUNT(*) FILTER (WHERE c.codigo <> 'TUR')
  INTO v_turismo_total, v_turismo_otra_carrera
  FROM usuarios u
  JOIN grupos g ON g.id_grupo = u.id_grupo
  JOIN carreras c ON c.id_carrera = g.id_carrera
  JOIN horarios_academicos h ON h.id_grupo = g.id_grupo
  WHERE u.id_usuario = v_turismo_usuario
    AND EXISTS (
      SELECT 1
      FROM usuario_roles ur
      JOIN roles r ON r.id_rol = ur.id_rol
      WHERE ur.id_usuario = u.id_usuario
        AND r.codigo = 'ESTUDIANTE'
    );

  IF v_turismo_total <> 8 OR v_turismo_otra_carrera <> 0 THEN
    RAISE EXCEPTION
      'Filtro Turismo incorrecto: total %, otras carreras %.',
      v_turismo_total, v_turismo_otra_carrera;
  END IF;

  SELECT COUNT(*),
         COUNT(*) FILTER (WHERE c.codigo <> 'ITI')
  INTO v_iti_total, v_iti_otra_carrera
  FROM usuarios u
  JOIN grupos g ON g.id_grupo = u.id_grupo
  JOIN carreras c ON c.id_carrera = g.id_carrera
  JOIN horarios_academicos h ON h.id_grupo = g.id_grupo
  WHERE u.id_usuario = v_iti_usuario
    AND EXISTS (
      SELECT 1
      FROM usuario_roles ur
      JOIN roles r ON r.id_rol = ur.id_rol
      WHERE ur.id_usuario = u.id_usuario
        AND r.codigo = 'ESTUDIANTE'
    );

  IF v_iti_total <> 8 OR v_iti_otra_carrera <> 0 THEN
    RAISE EXCEPTION
      'Filtro ITI incorrecto: total %, otras carreras %.',
      v_iti_total, v_iti_otra_carrera;
  END IF;

  SELECT COUNT(*),
         COUNT(*) FILTER (WHERE c.codigo <> 'ITI')
  INTO v_docente_total, v_docente_otra_carrera
  FROM usuarios u
  JOIN docentes d ON d.id_usuario = u.id_usuario
  JOIN horarios_academicos h ON h.id_docente = d.id_docente
  JOIN carreras c ON c.id_carrera = h.id_carrera
  WHERE u.id_usuario = v_docente_usuario
    AND EXISTS (
      SELECT 1
      FROM usuario_roles ur
      JOIN roles r ON r.id_rol = ur.id_rol
      WHERE ur.id_usuario = u.id_usuario
        AND r.codigo = 'DOCENTE'
    )
    AND d.codigo = 'ITI-DOC-01';

  IF v_docente_total <> 6 OR v_docente_otra_carrera <> 0 THEN
    RAISE EXCEPTION
      'Filtro docente incorrecto: total %, otras carreras %.',
      v_docente_total, v_docente_otra_carrera;
  END IF;

  SELECT COUNT(*) INTO v_talleres_total
  FROM horarios_academicos
  WHERE id_taller IS NOT NULL
    AND numero_semestre BETWEEN 1 AND 6;

  SELECT COUNT(*) INTO v_talleres_semestre_7
  FROM horarios_academicos
  WHERE id_taller IS NOT NULL
    AND numero_semestre = 7;

  IF v_talleres_total <> 18 OR v_talleres_semestre_7 <> 0 THEN
    RAISE EXCEPTION
      'Talleres incorrectos: semestres 1-6 %, semestre 7 %.',
      v_talleres_total, v_talleres_semestre_7;
  END IF;

  IF EXISTS (
    SELECT g.id_grupo
    FROM grupos g
    LEFT JOIN horarios_academicos h
      ON h.id_grupo = g.id_grupo
      AND h.id_taller IS NOT NULL
    GROUP BY g.id_grupo, g.numero_semestre
    HAVING (g.numero_semestre BETWEEN 1 AND 6 AND COUNT(h.id_horario) <> 1)
       OR (g.numero_semestre = 7 AND COUNT(h.id_horario) <> 0)
  ) THEN
    RAISE EXCEPTION
      'La cantidad de talleres por grupo no corresponde al semestre.';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM horarios_academicos a
    JOIN horarios_academicos b
      ON a.id_horario < b.id_horario
      AND a.periodo && b.periodo
      AND (
        a.id_grupo = b.id_grupo
        OR a.id_docente = b.id_docente
        OR a.id_aula = b.id_aula
      )
  )
  INTO v_hay_choques;

  IF v_hay_choques THEN
    RAISE EXCEPTION 'Se encontraron choques de grupo, docente o aula.';
  END IF;

  SELECT BOOL_OR(h.hora_fin - h.hora_inicio = INTERVAL '2 hours'),
         BOOL_OR(h.hora_fin - h.hora_inicio = INTERVAL '3 hours'),
         BOOL_OR(h.hora_fin - h.hora_inicio = INTERVAL '4 hours')
  INTO v_hay_duracion_2, v_hay_duracion_3, v_hay_duracion_4
  FROM horarios_academicos h
  WHERE h.id_materia IS NOT NULL;

  IF NOT COALESCE(v_hay_duracion_2, FALSE)
     OR NOT COALESCE(v_hay_duracion_3, FALSE)
     OR NOT COALESCE(v_hay_duracion_4, FALSE) THEN
    RAISE EXCEPTION 'Faltan clases de 2, 3 o 4 horas en el horario de prueba.';
  END IF;

  RAISE NOTICE
    'OK: Turismo %, ITI %, docente %, 18 talleres y sin cruces.',
    v_turismo_total, v_iti_total, v_docente_total;
END
$$;

ROLLBACK;
