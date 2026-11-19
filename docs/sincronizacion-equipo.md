# Sincronización entre GitHub, Drive y Trello

GitHub, Drive y Trello tienen funciones distintas:

| Herramienta | Debe contener |
|---|---|
| GitHub | Código, SQL, documentación técnica versionada y decisiones |
| Google Drive | Presentaciones, entrevistas, capturas, videos, documentos firmados y archivos pesados |
| Trello | Estado de las tareas, responsables, revisores, checklists y bloqueos |

## Cambios de esta actualización

- La base objetivo cambió de MySQL/MariaDB a PostgreSQL/Supabase.
- La salida de transporte es a las **12:00 p. m. (mediodía)**.
- F0-04 permanece en proceso porque faltan autorización, precios finales y confirmación del pago simulado.
- La cuarta ruta permanece `POR_CONFIRMAR` hasta tener datos oficiales.
- Se agregó el esquema PostgreSQL y el documento de roles/permisos a GitHub.

## Pasos manuales para el equipo

1. En Trello, cambiar el texto de F3-02/F3-03 a “12:00 p. m. (mediodía)”.
2. En Trello, mover F0-04 fuera de Completado hasta completar sus tres pendientes.
3. En Trello, agregar la tarjeta `F1-05 — Migrar base de datos a PostgreSQL/Supabase`.
4. En Drive, subir los documentos de rutas, pagos y roles dentro de una carpeta `Fase 0 - Definición y arquitectura`.
5. En cada tarjeta de Trello, pegar el enlace al archivo correspondiente de Drive y al archivo de GitHub.
6. No subir secretos, claves de Supabase, datos personales ni información bancaria.
