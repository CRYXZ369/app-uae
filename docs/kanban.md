# Kanban del proyecto App Unificada UAE

Estados: `Backlog` -> `Por hacer` -> `En progreso` -> `En revisión` -> `Hecho`. Una persona es responsable; otra puede ser revisora.

## Fase 0 - Organización y levantamiento

| ID | Actividad | Responsable | Estado |
|---|---|---|---|
| F0-01 | Confirmar usuarios, roles y permisos con la universidad | CRYXZ + equipo | Por hacer |
| F0-02 | Entrevistar cafeterías y validar menú/pedido | Camila + Carlos | Por hacer |
| F0-03 | Confirmar cuatro rutas, paradas y horarios | Kike + Carlos | Por hacer |
| F0-04 | Confirmar reglas de mensualidades y constancias | CRYXZ + administración | Por hacer |
| F0-05 | Crear datos ficticios y criterios de aceptación | Carlos | Por hacer |

## Fase 1 - Base técnica

| ID | Actividad | Responsable | Estado |
|---|---|---|---|
| F1-01 | Crear proyecto Flutter y navegación base | Donovan | Por hacer |
| F1-02 | Crear API Java REST y configuración por entorno | CRYXZ | Por hacer |
| F1-03 | Crear migraciones de identidad, roles y permisos | CRYXZ | Por hacer |
| F1-04 | Definir contrato OpenAPI inicial | CRYXZ + Kike | Por hacer |
| F1-05 | Crear tema visual basado en Figma | Camila | Por hacer |
| F1-06 | Configurar CI para compilación y pruebas | CRYXZ | Por hacer |
| F1-07 | Migrar esquema y conexión a PostgreSQL/Supabase | CRYXZ | En proceso |

## Fase 2 - MVP académico y comunicación

| ID | Actividad | Responsable | Estado |
|---|---|---|---|
| F2-01 | Login, sesión expirada y perfil | CRYXZ + Donovan | En progreso ([detalle](modules/f2-01-sesion.md)) |
| F2-02 | Inicio con tarjetas y accesos rápidos | Donovan | Por hacer |
| F2-03 | Horarios filtrados por carrera/grupo | Donovan + CRYXZ | Por hacer |
| F2-04 | Materias, tareas y progreso | Donovan | Por hacer |
| F2-05 | Avisos segmentados | Camila + CRYXZ | Por hacer |
| F2-06 | Votaciones y resultados | Camila + CRYXZ | Por hacer |
| F2-07 | Pruebas de flujos académicos | Carlos | Por hacer |

## Fase 3 - Transporte

| ID | Actividad | Responsable | Estado |
|---|---|---|---|
| F3-01 | CRUD de rutas y paradas | Kike + CRYXZ | Por hacer |
| F3-02 | Horarios estimados por parada | Kike | Por hacer |
| F3-03 | Confirmación de salida de las 12:00 p. m. (mediodía) | Kike + Camila | Por hacer |
| F3-04 | Modelo de ubicación y última actualización | Kike + CRYXZ | Por hacer |
| F3-05 | Mapa/estado de unidad en Flutter | Donovan | Por hacer |
| F3-06 | Pruebas con ruta faltante POR_CONFIRMAR | Carlos | Por hacer |

## Fase 4 - Compras, pagos y documentos

| ID | Actividad | Responsable | Estado |
|---|---|---|---|
| F4-01 | Menús separados de ambas cafeterías | Camila + Kike | Por hacer |
| F4-02 | Carrito y pedido prototipo | Donovan + Kike | Por hacer |
| F4-03 | Catálogo de descuentos externos | Camila | Por hacer |
| F4-04 | Mensualidades y estados de cuenta | CRYXZ | Por hacer |
| F4-05 | Catálogo de servicios y constancias | CRYXZ | Por hacer |
| F4-06 | Barra de progreso y comprobante | Donovan + Camila | Por hacer |
| F4-07 | Pruebas sin cobro real y sin tarjeta | Carlos | Por hacer |

## Fase 5 - Integración y entrega

| ID | Actividad | Responsable | Estado |
|---|---|---|---|
| F5-01 | Integración de todos los módulos | CRYXZ | Por hacer |
| F5-02 | Pruebas de permisos por rol | Carlos + CRYXZ | Por hacer |
| F5-03 | Pruebas de API y base de datos | Kike + Carlos | Por hacer |
| F5-04 | Prueba de usabilidad con estudiantes | Camila + equipo | Por hacer |
| F5-05 | Manual técnico y manual de usuario | Carlos + Camila | Por hacer |
| F5-06 | Demo, presentación y retrospectiva | Todo el equipo | Por hacer |

## Cómo mover una tarjeta

Una tarjeta debe incluir objetivo, responsable, revisora, dependencias, criterios de aceptación y evidencia esperada. No se mueve a `En revisión` sin pruebas; no se mueve a `Hecho` sin revisión.
