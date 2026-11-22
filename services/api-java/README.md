# API REST Java

Este es el destino de la migración desde `services/desktop-legacy/backend-java`. La API será consumida por Flutter y será la autoridad para autenticación, permisos, estados, pagos y votos. La base objetivo es PostgreSQL en Supabase.

## Módulos de implementación

Implementar en este orden: `identity`, `academic`, `announcements`, `polls`, `transport`, `cafeteria`, `commerce`, `billing`, `documents` y `admin`.

## Reglas del servicio

- Configuración por variables de entorno; nunca credenciales en código.
- Usar el driver PostgreSQL y `DB_URL` con `sslmode=require` en conexiones remotas.
- Respuestas JSON consistentes y errores con código, mensaje seguro y detalles de validación.
- Autorización en cada caso de uso, no solo en la interfaz.
- Transacciones para pedidos, pagos simulados y votos.
- Logs sin contraseñas, tokens, datos de pago ni información académica innecesaria.

La implementación del API se inicia en la Fase 1 del tablero. Hasta entonces, este directorio es el límite claro entre el cliente legado y el nuevo backend.

## Configuración local

Las variables `DB_URL`, `DB_USER`, `DB_PASSWORD` y `SERVER_PORT` pueden
mantenerse en un archivo local `.env`, excluido de Git. No compartirlo ni
incluirlo en Flutter. El archivo no se carga automáticamente: la futura API
debe definir cómo leerlo o recibir esas variables del entorno. La configuración
de conexión por sí sola no crea endpoints de autenticación; las conexiones
remotas deberán verificar TLS y el certificado del servidor.
