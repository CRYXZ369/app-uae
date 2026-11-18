# Módulos y alcance

## MVP de la primera entrega

### 1. Inicio de sesión y perfiles

Estudiantes, docentes, trabajadores, directivos, administración escolar, gestión académica, rectoría, CCE, cafetería y soporte. El perfil determina el menú y los permisos.

### 2. Inicio y notificaciones

Tarjetas de promedio, asistencia, próximas clases, tareas urgentes y avisos. Toda pantalla debe tener estados de carga, sin datos, error y sesión expirada.

### 3. Académico

- Horario filtrado por carrera, semestre y grupo.
- Materias con docente, aula, progreso y recursos.
- Tareas con fecha, prioridad, estado y descripción.
- Calificación estimada según entregables y escala definida por el docente.
- Notificaciones de clase próxima, entrega vencida y cambio de horario.

### 4. Transporte

Las rutas no deben quedar codificadas en Flutter. Inicialmente se cargarán como datos administrables:

- Ruta Larga: Del Rodeo/Tlalnepantla-Atizapán hacia UAE, pasando por Nicolás Romero.
- Ruta Corta: El Charco, Nicolás Romero, hacia UAE.
- Ruta Naucalpan: Naucalpan hacia UAE.
- Ruta por confirmar con la comunidad.

Cada ruta tendrá salida, paradas ordenadas, hora estimada por parada, unidad, estado y última ubicación. La ruta faltante se registra como `POR_CONFIRMAR`, nunca se inventa.

La salida de las 12:00 a. m. UAE -> El Charco funcionará como votación/confirmación de lunes a viernes: ventana de confirmación, mínimo de pasajeros configurable, cierre automático, resultado visible y registro auditable.

### 5. Compras y cafeterías

La sección agrupa:

- Cafetería Arriba y Cafetería Abajo.
- Menú, disponibilidad, carrito, pedido, estado y retiro.
- Prototipo sin cobro real en la primera entrega.
- Descuentos externos: Figma, YouTube Premium, Spotify y otros, con logo, descripción, vigencia y enlace oficial.

### 6. Pagos y documentos

- Mensualidades pendientes con periodo, monto, vencimiento y estado.
- Servicios: constancia de estudios ($75), constancia urgente ($100) y catálogo administrable.
- Confirmación de pago, comprobante y barra de progreso del documento.
- En MVP se simula el pago; no se deben guardar datos de tarjeta.

### 7. Avisos y participación

Avisos segmentados por audiencia y categoría: escolar, académica, rectoría, marketing, CCE y emergencia. Las votaciones tienen fechas, opciones, una respuesta por usuario, resultados y cierre.

## Fases posteriores

1. Integración de cobro real con proveedor autorizado.
2. Venta y gestión completa de inventario de ambas cafeterías.
3. GPS en vivo con dispositivo/unidad y panel operativo.
4. Portal administrativo completo y auditoría.
5. Recursos académicos, asistencia avanzada y analítica.

## Reglas de seguridad y privacidad

- Un alumno solo ve su horario, materias, tareas, pagos y notificaciones.
- Un docente ve sus grupos y puede publicar tareas/calificaciones en ellos.
- Cafetería ve únicamente sus menús y pedidos.
- Administración gestiona pagos, documentos y avisos según permiso.
- Un voto no se puede duplicar; definir con la universidad si será anónimo o auditable.
- No mostrar ubicación exacta de una persona; solo la unidad autorizada.
