-- Datos académicos ficticios para desarrollo. No representan un horario oficial.
-- Aplicar después de 03_ddl_academico_postgres.sql.

BEGIN;

INSERT INTO carreras (codigo, nombre) VALUES
  ('ITI', 'Ingeniería en Tecnologías de la Información'),
  ('TUR', 'Turismo'),
  ('ADM', 'Licenciatura en Administración')
ON CONFLICT (codigo) DO UPDATE
SET nombre = EXCLUDED.nombre,
    activa = TRUE;

INSERT INTO semestres (numero, nombre, tiene_taller_semanal) VALUES
  (1, '1er semestre', TRUE),
  (2, '2do semestre', TRUE),
  (3, '3er semestre', TRUE),
  (4, '4to semestre', TRUE),
  (5, '5to semestre', TRUE),
  (6, '6to semestre', TRUE),
  (7, '7mo semestre', FALSE),
  (8, '8vo semestre', FALSE),
  (9, '9no semestre', FALSE),
  (10, '10mo semestre', FALSE),
  (11, '11vo semestre', FALSE),
  (12, '12vo semestre', FALSE)
ON CONFLICT (numero) DO UPDATE
SET nombre = EXCLUDED.nombre,
    tiene_taller_semanal = EXCLUDED.tiene_taller_semanal;

INSERT INTO grupos (
  id_carrera, numero_semestre, codigo, nombre, periodo_escolar
)
SELECT c.id_carrera,
       s.numero,
       'S' || s.numero || '-A',
       CASE s.numero
         WHEN 1 THEN '1ro'
         WHEN 2 THEN '2do'
         WHEN 3 THEN '3ro'
         WHEN 4 THEN '4to'
         WHEN 5 THEN '5to'
         WHEN 6 THEN '6to'
         WHEN 7 THEN '7mo'
       END || ' A',
       'DEMO'
FROM carreras c
CROSS JOIN semestres s
WHERE c.codigo IN ('ITI', 'TUR', 'ADM')
ON CONFLICT (id_carrera, numero_semestre, codigo, periodo_escolar) DO UPDATE
SET nombre = EXCLUDED.nombre,
    activo = TRUE;

WITH plan_estudios (codigo_carrera, numero_semestre, nombres) AS (
  VALUES
    ('ITI', 1, ARRAY[
      'Programación I', 'Matemáticas Discretas', 'Fundamentos de TI',
      'Comunicación Oral y Escrita', 'Inglés Técnico I', 'Física General',
      'Introducción a Redes'
    ]),
    ('ITI', 2, ARRAY[
      'Programación II', 'Estructuras de Datos', 'Álgebra Lineal',
      'Sistemas Operativos', 'Redes I', 'Inglés Técnico II',
      'Probabilidad y Estadística'
    ]),
    ('ITI', 3, ARRAY[
      'Programación Orientada a Objetos', 'Bases de Datos I',
      'Desarrollo Web I', 'Arquitectura de Computadoras', 'Redes II',
      'Ingeniería de Requisitos', 'Matemáticas Aplicadas'
    ]),
    ('ITI', 4, ARRAY[
      'Desarrollo Web II', 'Bases de Datos II', 'Seguridad Informática I',
      'Administración de Sistemas', 'Programación Móvil I',
      'Ingeniería de Software I', 'Investigación de Operaciones'
    ]),
    ('ITI', 5, ARRAY[
      'Programación Móvil II', 'Computación en la Nube',
      'Ciberseguridad', 'Redes Inalámbricas', 'Gestión de Proyectos TI',
      'Experiencia de Usuario', 'Calidad de Software'
    ]),
    ('ITI', 6, ARRAY[
      'DevOps', 'Inteligencia Artificial', 'Análisis de Datos',
      'Auditoría de TI', 'Administración de Bases de Datos',
      'Aplicaciones Empresariales', 'Emprendimiento Tecnológico'
    ]),
    ('ITI', 7, ARRAY[
      'Proyecto Integrador I', 'Arquitectura de Software',
      'Seguridad de Aplicaciones', 'Gobierno de TI',
      'Internet de las Cosas', 'Ética Profesional', 'Estadía Profesional'
    ]),
    ('TUR', 1, ARRAY[
      'Introducción al Turismo', 'Geografía Turística',
      'Patrimonio Cultural', 'Comunicación Profesional',
      'Inglés Turístico I', 'Fundamentos de Administración',
      'Servicio al Cliente'
    ]),
    ('TUR', 2, ARRAY[
      'Patrimonio Natural', 'Historia del Arte', 'Inglés Turístico II',
      'Operación de Agencias de Viajes', 'Estadística Aplicada',
      'Turismo Sustentable I', 'Expresión Oral'
    ]),
    ('TUR', 3, ARRAY[
      'Diseño de Productos Turísticos', 'Guianza Turística',
      'Inglés Turístico III', 'Mercadotecnia Turística',
      'Legislación Turística', 'Cultura Gastronómica',
      'Costos para Servicios'
    ]),
    ('TUR', 4, ARRAY[
      'Gestión Hotelera', 'Organización de Eventos',
      'Turismo Sustentable II', 'Francés Turístico I',
      'Sistemas de Reservaciones', 'Investigación Turística',
      'Calidad en el Servicio'
    ]),
    ('TUR', 5, ARRAY[
      'Administración de Restaurantes', 'Turismo de Aventura',
      'Inglés Turístico IV', 'Promoción de Destinos',
      'Transporte Turístico', 'Emprendimiento Turístico',
      'Gestión de Grupos'
    ]),
    ('TUR', 6, ARRAY[
      'Planeación de Destinos', 'Turismo Comunitario',
      'Francés Turístico II', 'Gestión de Empresas Turísticas',
      'Seminario de Investigación', 'Finanzas Turísticas',
      'Práctica Profesional I'
    ]),
    ('TUR', 7, ARRAY[
      'Proyecto Integrador Turístico', 'Desarrollo Regional',
      'Turismo Internacional', 'Gestión de Riesgos Turísticos',
      'Seminario de Titulación', 'Ética Profesional',
      'Práctica Profesional II'
    ]),
    ('ADM', 1, ARRAY[
      'Fundamentos de Administración', 'Contabilidad I',
      'Matemáticas para Negocios', 'Comunicación Empresarial',
      'Introducción a la Economía', 'Inglés I',
      'Desarrollo Organizacional'
    ]),
    ('ADM', 2, ARRAY[
      'Proceso Administrativo', 'Contabilidad II',
      'Estadística para Negocios', 'Microeconomía',
      'Derecho Empresarial', 'Inglés II',
      'Comportamiento Organizacional'
    ]),
    ('ADM', 3, ARRAY[
      'Administración de Recursos Humanos', 'Costos',
      'Macroeconomía', 'Mercadotecnia I',
      'Investigación de Mercados', 'Inglés III',
      'Matemáticas Financieras'
    ]),
    ('ADM', 4, ARRAY[
      'Administración de Operaciones', 'Finanzas I',
      'Mercadotecnia II', 'Derecho Laboral',
      'Planeación Estratégica', 'Inglés IV',
      'Sistemas de Información Administrativa'
    ]),
    ('ADM', 5, ARRAY[
      'Gestión del Talento', 'Finanzas II',
      'Administración de la Calidad', 'Comercio Internacional',
      'Presupuestos', 'Emprendimiento',
      'Responsabilidad Social Empresarial'
    ]),
    ('ADM', 6, ARRAY[
      'Consultoría Administrativa', 'Auditoría Administrativa',
      'Gestión de Proyectos', 'Administración Pública',
      'Análisis de Inversiones', 'Seminario de Investigación',
      'Negociación Empresarial'
    ]),
    ('ADM', 7, ARRAY[
      'Proyecto Integrador Administrativo', 'Dirección Estratégica',
      'Gestión del Cambio', 'Ética Empresarial',
      'Seminario de Titulación', 'Innovación de Negocios',
      'Práctica Profesional'
    ])
),
materias_catalogo AS (
  SELECT c.id_carrera,
         p.numero_semestre,
         p.codigo_carrera || '-S' ||
           LPAD(p.numero_semestre::TEXT, 2, '0') || '-M' ||
           LPAD(materia.secuencia::TEXT, 2, '0') AS codigo,
         materia.nombre
  FROM plan_estudios p
  JOIN carreras c ON c.codigo = p.codigo_carrera
  CROSS JOIN LATERAL
    UNNEST(p.nombres) WITH ORDINALITY AS materia(nombre, secuencia)
)
INSERT INTO materias (codigo, id_carrera, numero_semestre, nombre)
SELECT codigo, id_carrera, numero_semestre, nombre
FROM materias_catalogo
ON CONFLICT (codigo) DO UPDATE
SET id_carrera = EXCLUDED.id_carrera,
    numero_semestre = EXCLUDED.numero_semestre,
    nombre = EXCLUDED.nombre;

INSERT INTO docentes (codigo, nombre_completo) VALUES
  ('ITI-DOC-01', 'Ana López Martínez'),
  ('ITI-DOC-02', 'Luis Hernández Cruz'),
  ('ITI-DOC-03', 'María Fernanda Torres'),
  ('ITI-DOC-04', 'Jorge Ramírez Soto'),
  ('ITI-DOC-05', 'Paola Reyes Mendoza'),
  ('ITI-DOC-06', 'Carlos Eduardo Vázquez'),
  ('ITI-DOC-07', 'Daniela Cruz Méndez'),
  ('TUR-DOC-01', 'Sofía Castillo Ramos'),
  ('TUR-DOC-02', 'Miguel Ángel Ríos'),
  ('TUR-DOC-03', 'Valeria Jiménez León'),
  ('TUR-DOC-04', 'Ricardo Flores Nava'),
  ('TUR-DOC-05', 'Elena Pacheco Díaz'),
  ('TUR-DOC-06', 'Gabriel Mendoza Ruiz'),
  ('TUR-DOC-07', 'Claudia Romero Silva'),
  ('ADM-DOC-01', 'Patricia Sánchez Mora'),
  ('ADM-DOC-02', 'Roberto Aguilar Vega'),
  ('ADM-DOC-03', 'Laura Méndez Ortiz'),
  ('ADM-DOC-04', 'Fernando Pérez Luna'),
  ('ADM-DOC-05', 'Gabriela Navarro Cruz'),
  ('ADM-DOC-06', 'Héctor Salgado Reyes'),
  ('ADM-DOC-07', 'Diana Contreras Gil'),
  ('ITI-EXT-DOC-01', 'Andrés Valdez Moreno'),
  ('ITI-EXT-DOC-02', 'Mónica Estrada Pérez'),
  ('ITI-EXT-DOC-03', 'Raúl Cervantes Ríos'),
  ('ITI-EXT-DOC-04', 'Beatriz Molina Soto'),
  ('ITI-EXT-DOC-05', 'Ernesto Cárdenas Ruiz'),
  ('ITI-EXT-DOC-06', 'Verónica Luna Paredes'),
  ('ITI-EXT-DOC-07', 'Sergio Fuentes Lara'),
  ('TALLER-DOC-FUT', 'Iván Morales Vega'),
  ('TALLER-DOC-VOL', 'Andrea Pérez Solís'),
  ('TALLER-DOC-KIC', 'Óscar Ramírez León'),
  ('TALLER-DOC-DAN', 'Renata Campos Gil'),
  ('TALLER-DOC-TEA', 'Emilio Torres Rojas'),
  ('TALLER-DOC-YOG', 'Natalia Herrera Cruz')
ON CONFLICT (codigo) DO UPDATE
SET nombre_completo = EXCLUDED.nombre_completo,
    activo = TRUE;

INSERT INTO aulas (codigo, nombre) VALUES
  ('ITI-A01', 'PA 1'),
  ('ITI-A02', 'PA 2'),
  ('ITI-A03', 'GS 2'),
  ('ITI-A04', 'GS 7'),
  ('ITI-A05', 'PJ 1'),
  ('ITI-A06', 'PJ 2'),
  ('ITI-A07', 'Laboratorio TI'),
  ('TUR-A01', 'Turismo 1'),
  ('TUR-A02', 'Turismo 2'),
  ('TUR-A03', 'GS 3'),
  ('TUR-A04', 'GS 4'),
  ('TUR-A05', 'PJ 3'),
  ('TUR-A06', 'PJ 4'),
  ('TUR-A07', 'Sala de Turismo'),
  ('ADM-A01', 'Administración 1'),
  ('ADM-A02', 'Administración 2'),
  ('ADM-A03', 'PA 3'),
  ('ADM-A04', 'PA 4'),
  ('ADM-A05', 'PJ 5'),
  ('ADM-A06', 'PJ 6'),
  ('ADM-A07', 'Sala de Administración'),
  ('ITI-EXT-AULA-01', 'Laboratorio de Proyectos 1'),
  ('ITI-EXT-AULA-02', 'Laboratorio de Proyectos 2'),
  ('ITI-EXT-AULA-03', 'Laboratorio de Proyectos 3'),
  ('ITI-EXT-AULA-04', 'Laboratorio de Proyectos 4'),
  ('ITI-EXT-AULA-05', 'Laboratorio de Proyectos 5'),
  ('ITI-EXT-AULA-06', 'Laboratorio de Proyectos 6'),
  ('ITI-EXT-AULA-07', 'Laboratorio de Proyectos 7'),
  ('TAL-FUT', 'Cancha de fútbol'),
  ('TAL-VOL', 'Cancha de voleibol'),
  ('TAL-KIC', 'Cancha de kickball'),
  ('TAL-DAN', 'Sala de danza'),
  ('TAL-TEA', 'Sala de teatro'),
  ('TAL-YOG', 'Espacio de yoga'),
  ('MULTIUSOS', 'Aula de usos múltiples')
ON CONFLICT (codigo) DO UPDATE
SET nombre = EXCLUDED.nombre,
    activa = TRUE;

INSERT INTO talleres (codigo, nombre, orden) VALUES
  ('FUT', 'Fútbol', 1),
  ('VOL', 'Volleyball', 2),
  ('KIC', 'Kickball', 3),
  ('DAN', 'Danza', 4),
  ('TEA', 'Teatro', 5),
  ('YOG', 'Yoga', 6)
ON CONFLICT (codigo) DO UPDATE
SET nombre = EXCLUDED.nombre,
    orden = EXCLUDED.orden,
    activo = TRUE;

WITH horario_base AS (
  SELECT g.id_grupo,
         g.id_carrera,
         g.numero_semestre,
         c.codigo AS codigo_carrera,
         materia.id_materia,
         docente.id_docente,
         aula.id_aula,
         ((g.numero_semestre - 1) * 7 + asignacion.secuencia - 1) % 15
           AS bloque
  FROM grupos g
  JOIN carreras c ON c.id_carrera = g.id_carrera
  CROSS JOIN GENERATE_SERIES(1, 7) AS asignacion(secuencia)
  JOIN materias materia
    ON materia.codigo = c.codigo || '-S' ||
      LPAD(g.numero_semestre::TEXT, 2, '0') || '-M' ||
      LPAD(asignacion.secuencia::TEXT, 2, '0')
  JOIN docentes docente
    ON docente.codigo = c.codigo || '-DOC-' ||
      LPAD(asignacion.secuencia::TEXT, 2, '0')
  JOIN aulas aula
    ON aula.codigo = c.codigo || '-A' ||
      LPAD(asignacion.secuencia::TEXT, 2, '0')
  WHERE NOT (c.codigo = 'ITI' AND g.numero_semestre = 7)
)
INSERT INTO horarios_academicos (
  id_grupo, id_carrera, numero_semestre, id_materia, id_taller,
  id_docente, id_aula, dia_semana, hora_inicio, hora_fin
)
SELECT base.id_grupo,
       base.id_carrera,
       base.numero_semestre,
       base.id_materia,
       NULL,
       base.id_docente,
       base.id_aula,
       CASE (base.bloque / 3)
         WHEN 0 THEN 'Lunes'
         WHEN 1 THEN 'Martes'
         WHEN 2 THEN 'Miércoles'
         WHEN 3 THEN 'Jueves'
         ELSE 'Viernes'
       END,
       CASE (base.bloque % 3)
         WHEN 0 THEN TIME '08:00'
         WHEN 1 THEN TIME '10:00'
         ELSE TIME '13:00'
       END,
       CASE (base.bloque % 3)
         WHEN 0 THEN TIME '10:00'
         WHEN 1 THEN TIME '12:00'
         ELSE TIME '15:00'
       END
FROM horario_base base
ON CONFLICT (id_grupo, dia_semana, hora_inicio) DO UPDATE
SET id_carrera = EXCLUDED.id_carrera,
    numero_semestre = EXCLUDED.numero_semestre,
    id_materia = EXCLUDED.id_materia,
    id_taller = EXCLUDED.id_taller,
    id_docente = EXCLUDED.id_docente,
    id_aula = EXCLUDED.id_aula,
    hora_fin = EXCLUDED.hora_fin;

WITH grupos_taller AS (
  SELECT g.id_grupo,
         g.id_carrera,
         g.numero_semestre,
         ROW_NUMBER() OVER (ORDER BY c.codigo, g.numero_semestre) - 1
           AS orden_grupo
  FROM grupos g
  JOIN carreras c ON c.id_carrera = g.id_carrera
  WHERE g.numero_semestre BETWEEN 1 AND 6
),
asignaciones AS (
  SELECT grupo.*,
         taller.id_taller,
         docente.id_docente,
         aula.id_aula,
         (grupo.orden_grupo % 5)::INTEGER + 1 AS dia_numero
  FROM grupos_taller grupo
  JOIN talleres taller
    ON taller.orden = (grupo.orden_grupo % 6)::INTEGER + 1
  JOIN docentes docente
    ON docente.codigo = 'TALLER-DOC-' || taller.codigo
  JOIN aulas aula ON aula.codigo = 'TAL-' || taller.codigo
)
INSERT INTO horarios_academicos (
  id_grupo, id_carrera, numero_semestre, id_materia, id_taller,
  id_docente, id_aula, dia_semana, hora_inicio, hora_fin
)
SELECT asignacion.id_grupo,
       asignacion.id_carrera,
       asignacion.numero_semestre,
       NULL,
       asignacion.id_taller,
       asignacion.id_docente,
       asignacion.id_aula,
       CASE asignacion.dia_numero
         WHEN 1 THEN 'Lunes'
         WHEN 2 THEN 'Martes'
         WHEN 3 THEN 'Miércoles'
         WHEN 4 THEN 'Jueves'
         ELSE 'Viernes'
       END,
       TIME '12:00',
       TIME '13:00'
FROM asignaciones asignacion
ON CONFLICT (id_grupo, dia_semana, hora_inicio) DO UPDATE
SET id_carrera = EXCLUDED.id_carrera,
    numero_semestre = EXCLUDED.numero_semestre,
    id_materia = EXCLUDED.id_materia,
    id_taller = EXCLUDED.id_taller,
    id_docente = EXCLUDED.id_docente,
    id_aula = EXCLUDED.id_aula,
    hora_fin = EXCLUDED.hora_fin;

WITH horario_extendido (
  codigo_materia, codigo_docente, codigo_aula,
  dia_semana, hora_inicio, hora_fin
) AS (
  VALUES
    ('ITI-S07-M01', 'ITI-EXT-DOC-01', 'ITI-EXT-AULA-01',
      'Lunes', TIME '08:00', TIME '12:00'),
    ('ITI-S07-M02', 'ITI-EXT-DOC-02', 'ITI-EXT-AULA-02',
      'Lunes', TIME '13:00', TIME '15:00'),
    ('ITI-S07-M03', 'ITI-EXT-DOC-03', 'ITI-EXT-AULA-03',
      'Martes', TIME '08:00', TIME '11:00'),
    ('ITI-S07-M04', 'ITI-EXT-DOC-04', 'ITI-EXT-AULA-04',
      'Miércoles', TIME '08:00', TIME '12:00'),
    ('ITI-S07-M05', 'ITI-EXT-DOC-05', 'ITI-EXT-AULA-05',
      'Jueves', TIME '10:00', TIME '13:00'),
    ('ITI-S07-M06', 'ITI-EXT-DOC-06', 'ITI-EXT-AULA-06',
      'Viernes', TIME '08:00', TIME '10:00'),
    ('ITI-S07-M07', 'ITI-EXT-DOC-07', 'ITI-EXT-AULA-07',
      'Viernes', TIME '13:00', TIME '15:00')
)
INSERT INTO horarios_academicos (
  id_grupo, id_carrera, numero_semestre, id_materia, id_taller,
  id_docente, id_aula, dia_semana, hora_inicio, hora_fin
)
SELECT grupo.id_grupo,
       grupo.id_carrera,
       grupo.numero_semestre,
       materia.id_materia,
       NULL,
       docente.id_docente,
       aula.id_aula,
       plan.dia_semana,
       plan.hora_inicio,
       plan.hora_fin
FROM horario_extendido plan
JOIN materias materia ON materia.codigo = plan.codigo_materia
JOIN carreras carrera ON carrera.codigo = 'ITI'
JOIN grupos grupo
  ON grupo.id_carrera = carrera.id_carrera
  AND grupo.numero_semestre = 7
JOIN docentes docente ON docente.codigo = plan.codigo_docente
JOIN aulas aula ON aula.codigo = plan.codigo_aula
ON CONFLICT (id_grupo, dia_semana, hora_inicio) DO UPDATE
SET id_carrera = EXCLUDED.id_carrera,
    numero_semestre = EXCLUDED.numero_semestre,
    id_materia = EXCLUDED.id_materia,
    id_taller = EXCLUDED.id_taller,
    id_docente = EXCLUDED.id_docente,
    id_aula = EXCLUDED.id_aula,
    hora_fin = EXCLUDED.hora_fin;

COMMIT;
