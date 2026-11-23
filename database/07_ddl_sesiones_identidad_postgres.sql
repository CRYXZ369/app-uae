-- Tokens opacos: solo se almacena el resumen SHA-256, nunca el token.
BEGIN;

CREATE TABLE sesiones_identidad (
  token_hash BYTEA PRIMARY KEY CHECK (octet_length(token_hash) = 32),
  id_usuario BIGINT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  creada_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  expira_en TIMESTAMPTZ NOT NULL,
  CONSTRAINT chk_sesion_expiracion CHECK (expira_en > creada_en)
);

ALTER TABLE sesiones_identidad ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON sesiones_identidad FROM PUBLIC;

CREATE INDEX idx_sesiones_identidad_usuario ON sesiones_identidad (id_usuario);
CREATE INDEX idx_sesiones_identidad_expira ON sesiones_identidad (expira_en);

-- Una dirección de correo debe identificar como máximo a una persona.
-- La migración falla si existen duplicados que difieren solo en mayúsculas.
DO $$
DECLARE
  columna_correo text;
BEGIN
  SELECT CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'usuarios' AND column_name = 'correo_institucional')
      THEN 'correo_institucional'
    WHEN EXISTS (SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'usuarios' AND column_name = 'email')
      THEN 'email'
    ELSE NULL
  END INTO columna_correo;
  IF columna_correo IS NULL THEN
    RAISE EXCEPTION 'No se encontró una columna de correo compatible en public.usuarios';
  END IF;
  EXECUTE format('CREATE UNIQUE INDEX idx_usuarios_email_normalizado ON public.usuarios (lower(%I))', columna_correo);
END $$;

COMMIT;
